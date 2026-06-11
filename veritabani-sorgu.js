(function () {
    const DEFAULT_SQL = `SELECT name AS TableName, create_date AS CreateDate
FROM sys.tables
ORDER BY name;`;

    const KATMAN_LABEL = {
        TDSTG: 'TDSTG',
        TDMAIN: 'TDMAIN',
        TDREPORT: 'TDREPORT'
    };

    let veriKaynaklari = [];
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

    async function loadKaynaklar() {
        try {
            veriKaynaklari = await ApiClient.getVeriKaynaklari();
        } catch (err) {
            console.warn('Veri kaynakları yüklenemedi:', err);
            veriKaynaklari = [];
        }
        syncKatmanSelect();
    }

    function syncKatmanSelect() {
        const sel = document.getElementById('vsKatmanSelect');
        if (!sel) return;

        if (veriKaynaklari.length) {
            sel.innerHTML = veriKaynaklari.map(v =>
                `<option value="${escapeHtml(v.katmanKodu)}" ${v.katmanKodu === selectedKatman ? 'selected' : ''}>${escapeHtml(v.katmanKodu)} — ${escapeHtml(v.veritabani)}</option>`
            ).join('');
        } else {
            sel.innerHTML = Object.keys(KATMAN_LABEL).map(k =>
                `<option value="${k}" ${k === selectedKatman ? 'selected' : ''}>${k}</option>`
            ).join('');
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
                setError(res.hata || 'Sorgu hatası');
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

    function apiErrorMessage(err) {
        const msg = err?.message || String(err);
        if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
            return `API'ye ulaşılamıyor. Proje klasöründe: dotnet run --project src\\MerkeziFinansalVeri.Api\\MerkeziFinansalVeri.Api.csproj — ardından sayfayı HTTP sunucusundan açın (file:// değil). Varsayılan API: ${ApiClient.baseUrl}`;
        }
        return msg;
    }

    function bindEvents() {
        document.getElementById('vsTestBtn')?.addEventListener('click', testConnection);
        document.getElementById('vsRunBtn')?.addEventListener('click', runQuery);
        document.getElementById('vsKatmanSelect')?.addEventListener('change', e => {
            selectedKatman = e.target.value;
        });
        document.getElementById('vsQueryInput')?.addEventListener('keydown', e => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                runQuery();
            }
        });
    }

    document.addEventListener('DOMContentLoaded', async () => {
        const input = document.getElementById('vsQueryInput');
        if (input && !input.value.trim()) input.value = DEFAULT_SQL;

        bindEvents();
        await loadKaynaklar();
        testConnection();
    });
})();
