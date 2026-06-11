(function () {
    const FALLBACK_SQL = `SELECT name AS TableName, create_date AS CreateDate
FROM sys.tables
ORDER BY name;`;

    let ayarlar = null;
    let selectedKatman = 'TDSTG';

    function escapeHtml(str) {
        return String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function setStatus(state, text) {
        const dot = document.getElementById('vsStatusDot');
        const label = document.getElementById('vsStatusText');
        if (!dot || !label) return;
        dot.className = 'vs-status-dot';
        if (state) dot.classList.add(state);
        label.textContent = text;
    }

    function setError(message) {
        const box = document.getElementById('vsQueryError');
        if (!box) return;
        if (!message) {
            box.hidden = true;
            box.textContent = '';
            return;
        }
        box.hidden = false;
        box.textContent = message;
    }

    function setMeta(text) {
        const meta = document.getElementById('vsQueryMeta');
        if (meta) meta.textContent = text || '';
    }

    function updateConnBadge(katmanKodu) {
        const badge = document.getElementById('vsConnBadge');
        if (!badge || !ayarlar?.katmanlar) return;

        const katman = ayarlar.katmanlar.find(k => k.katmanKodu === katmanKodu);
        if (!katman) {
            badge.textContent = '';
            return;
        }

        const port = katman.port === 1433 ? '' : `:${katman.port}`;
        badge.textContent = `${katman.sunucu}${port} / ${katman.veritabani}`;
        badge.title = `${katman.sunucu}:${katman.port} → ${katman.veritabani} (${katman.kimlikDogrulama})`;
    }

    function renderKatmanSelect() {
        const sel = document.getElementById('vsKatmanSelect');
        if (!sel) return;

        const katmanlar = ayarlar?.katmanlar?.length
            ? ayarlar.katmanlar
            : [
                { katmanKodu: 'TDSTG', veritabani: 'TDSTG' },
                { katmanKodu: 'TDMAIN', veritabani: 'TDMAIN' },
                { katmanKodu: 'TDREPORT', veritabani: 'TDREPORT' }
            ];

        sel.innerHTML = katmanlar.map(k =>
            `<option value="${escapeHtml(k.katmanKodu)}" ${k.katmanKodu === selectedKatman ? 'selected' : ''}>${escapeHtml(k.katmanKodu)} — ${escapeHtml(k.veritabani)}</option>`
        ).join('');

        updateConnBadge(selectedKatman);
    }

    function renderResults(payload) {
        const head = document.getElementById('vsResultsHead');
        const body = document.getElementById('vsResultsBody');
        const wrap = document.getElementById('vsResultsWrap');
        const empty = document.getElementById('vsResultsEmpty');
        if (!head || !body || !wrap) return;

        const cols = payload.kolonlar || [];
        const rows = payload.satirlar || [];

        head.innerHTML = `<tr>${cols.map(c => `<th>${escapeHtml(c)}</th>`).join('')}</tr>`;
        body.innerHTML = rows.map(row => {
            const cells = cols.map(col => {
                const val = row[col];
                const display = val === null || val === undefined ? '' : String(val);
                return `<td title="${escapeHtml(display)}">${escapeHtml(display)}</td>`;
            }).join('');
            return `<tr>${cells}</tr>`;
        }).join('');

        if (empty) empty.hidden = rows.length > 0;
        wrap.classList.toggle('has-data', rows.length > 0);

        let meta = `${payload.satirSayisi ?? rows.length} satır`;
        if (payload.sureMs != null) meta += ` · ${payload.sureMs} ms`;
        if (payload.kisitlandi) meta += ` · ilk ${payload.maxSatir} satır gösterildi`;
        setMeta(meta);
    }

    function apiErrorMessage(err) {
        const msg = err?.message || String(err);
        if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
            return `API'ye ulaşılamıyor. Proje kökünde start-api.bat çalıştırın, sayfayı HTTP sunucusundan açın (file:// değil). Varsayılan API: ${ApiClient.baseUrl}`;
        }
        return msg;
    }

    async function loadAyarlar() {
        try {
            ayarlar = await ApiClient.getVeritabaniSorguAyarlar();
            selectedKatman = ayarlar.varsayilanKatman || 'TDSTG';

            const hint = document.getElementById('vsConfigHint');
            if (hint && ayarlar.configDosyasi) {
                hint.textContent = `Bağlantı: ${ayarlar.configDosyasi} · Yalnızca SELECT · Ctrl+Enter ile çalıştır · max ${ayarlar.maxSatir} satır`;
            }

            const input = document.getElementById('vsQueryInput');
            if (input && !input.value.trim() && ayarlar.varsayilanSorgu) {
                input.value = ayarlar.varsayilanSorgu;
            }

            renderKatmanSelect();
        } catch (err) {
            console.warn('Sorgu ayarları yüklenemedi:', err);
            ayarlar = null;
            renderKatmanSelect();

            const input = document.getElementById('vsQueryInput');
            if (input && !input.value.trim()) input.value = FALLBACK_SQL;

            setStatus('err', apiErrorMessage(err));
        }
    }

    async function testConnection() {
        setStatus('pending', 'Bağlantı test ediliyor…');
        setError('');
        try {
            const katman = document.getElementById('vsKatmanSelect')?.value || selectedKatman;
            const res = await ApiClient.testVeritabaniSorguKatman(katman);
            if (res.basarili) {
                setStatus('ok', res.mesaj || 'Bağlantı başarılı.');
            } else {
                setStatus('err', res.mesaj || 'Bağlantı başarısız.');
            }
        } catch (err) {
            setStatus('err', apiErrorMessage(err));
        }
    }

    async function runQuery() {
        const sql = document.getElementById('vsQueryInput')?.value?.trim();
        const katman = document.getElementById('vsKatmanSelect')?.value || selectedKatman;
        const runBtn = document.getElementById('vsRunBtn');
        const testBtn = document.getElementById('vsTestBtn');

        if (!sql) {
            setError('Sorgu metni boş.');
            return;
        }

        setError('');
        setMeta('Sorgu çalıştırılıyor…');
        if (runBtn) runBtn.disabled = true;
        if (testBtn) testBtn.disabled = true;

        try {
            const res = await ApiClient.calistirVeritabaniSorgu({ katmanKodu: katman, sql });

            if (!res.basarili) {
                setMeta('');
                setError(res.hata || 'Sorgu başarısız.');
                const wrap = document.getElementById('vsResultsWrap');
                if (wrap) wrap.classList.remove('has-data');
                setStatus('err', `${katman} — sorgu hatası`);
                return;
            }

            renderResults(res);
            setStatus('ok', `${katman} — sorgu tamamlandı`);
        } catch (err) {
            setMeta('');
            setError(apiErrorMessage(err));
            const wrap = document.getElementById('vsResultsWrap');
            if (wrap) wrap.classList.remove('has-data');
        } finally {
            if (runBtn) runBtn.disabled = false;
            if (testBtn) testBtn.disabled = false;
        }
    }

    function bindEvents() {
        document.getElementById('vsTestBtn')?.addEventListener('click', testConnection);
        document.getElementById('vsRunBtn')?.addEventListener('click', runQuery);
        document.getElementById('vsKatmanSelect')?.addEventListener('change', e => {
            selectedKatman = e.target.value;
            updateConnBadge(selectedKatman);
        });
        document.getElementById('vsQueryInput')?.addEventListener('keydown', e => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                runQuery();
            }
        });
    }

    document.addEventListener('DOMContentLoaded', async () => {
        bindEvents();
        await loadAyarlar();
        if (document.getElementById('vsStatusDot')?.classList.contains('err')) return;
        testConnection();
    });
})();
