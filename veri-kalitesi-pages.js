(function () {
    let vkKurallarAyarlar = null;
    let vkKurallarSorgu = null;
    let vkGunlukSorgu = null;

    const VK_COLUMN_LABELS = {
        RuleId: 'Kural ID',
        RelTermFieldId: 'Alan ID',
        RunPeriodId: 'Periyot',
        QualityId: 'Kalite ID',
        ExactValue: 'Değer',
        QualityLevel: 'Seviye',
        RuleDesc: 'Açıklama',
        Status: 'Durum',
        ActiveFlag: 'Aktif',
        InsertDate: 'Eklenme',
        UpdatedDate: 'Güncelleme',
        UserName: 'Kullanıcı',
        ResponsibleAnalystName: 'Sorumlu Analist'
    };

    const GUNLUK_COLUMN_LABELS = {
        DataDate: 'Veri Tarihi',
        TableName: 'Tablo',
        FieldName: 'Alan',
        ExactValue: 'Beklenen Değer',
        ErrorDescription: 'Hata Açıklaması',
        QualityId: 'Kalite ID',
        QualityLevel: 'Kalite Seviyesi',
        RuleId: 'Kural ID',
        QualityProcedureName: 'Kalite Prosedürü'
    };

    function escapeHtml(str) {
        return String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function apiErrorMessage(err) {
        const msg = err?.message || String(err);
        if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
            return `API'ye ulaşılamıyor. start-api.bat çalıştırın. Varsayılan: ${ApiClient.baseUrl}`;
        }
        return msg;
    }

    function formatKurallarCell(col, val) {
        if (val === null || val === undefined) return '';
        const text = String(val);

        if (col === 'Status') {
            const lower = text.toLowerCase();
            if (lower === 'active' || lower === 'aktif' || lower === '1') {
                return '<span class="vk-badge ok">Aktif</span>';
            }
            if (lower === 'inactive' || lower === 'pasif' || lower === '0') {
                return '<span class="vk-badge off">Pasif</span>';
            }
        }

        if (col === 'ActiveFlag') {
            const active = text === '1' || text.toLowerCase() === 'true' || text.toLowerCase() === 'y';
            return `<span class="vk-badge ${active ? 'ok' : 'off'}">${active ? 'Evet' : 'Hayır'}</span>`;
        }

        return escapeHtml(text);
    }

    function formatGunlukCell(col, val) {
        if (val === null || val === undefined) return '';
        if (col === 'QualityLevel') {
            const level = Number(val);
            if (level <= 1) return `<span class="vk-badge fail">${escapeHtml(val)}</span>`;
            if (level <= 2) return `<span class="vk-badge warn">${escapeHtml(val)}</span>`;
            return `<span class="vk-badge ok">${escapeHtml(val)}</span>`;
        }
        return escapeHtml(String(val));
    }

    function buildResultTable(cols, rows, formatCell, columnLabels) {
        const headerCells = cols.map(c =>
            `<th>${escapeHtml(columnLabels[c] || c)}</th>`
        ).join('');

        const bodyRows = rows.map(row => {
            const cells = cols.map(col => {
                const display = formatCell(col, row[col]);
                const title = row[col] === null || row[col] === undefined ? '' : String(row[col]);
                return `<td title="${escapeHtml(title)}">${display}</td>`;
            }).join('');
            return `<tr>${cells}</tr>`;
        }).join('');

        const emptyRow = `<tr><td colspan="${cols.length || 1}">Kayıt bulunamadı.</td></tr>`;

        return `<table class="vk-table">
            <thead><tr>${headerCells}</tr></thead>
            <tbody>${bodyRows || emptyRow}</tbody>
        </table>`;
    }

    async function loadVkKurallarSorgu() {
        vkKurallarSorgu = null;
        vkKurallarAyarlar = null;

        try {
            vkKurallarAyarlar = await ApiClient.getVkKurallarAyarlar();
        } catch (err) {
            console.warn('VK kurallar ayarları yüklenemedi:', err);
        }

        try {
            vkKurallarSorgu = await ApiClient.getVkKurallarSorgu();
        } catch (err) {
            console.error('VK kurallar sorgusu yüklenemedi:', err);
            vkKurallarSorgu = { basarili: false, hata: apiErrorMessage(err) };
        }
    }

    async function loadVkGunlukSorgu() {
        vkGunlukSorgu = null;
        try {
            vkGunlukSorgu = await ApiClient.getVkGunlukSonuclarSorgu();
        } catch (err) {
            console.error('Günlük sonuçlar sorgusu yüklenemedi:', err);
            vkGunlukSorgu = { basarili: false, hata: apiErrorMessage(err) };
        }
    }

    function buildKurallarHTML() {
        const ayar = vkKurallarAyarlar;
        const data = vkKurallarSorgu;
        const sqlDosya = ayar?.sorguDosyasi || 'config/queries/vk-kurallar.sql';
        const katman = ayar?.katmanKodu || 'TDUTIL';

        if (!data) {
            return `<section class="vk-layout">
                <div class="vk-head">
                    <h3>Veri Kalitesi Kuralları</h3>
                    <p>TDUTIL veri kalitesi kuralları yükleniyor…</p>
                </div>
                <div class="vk-card vk-loading">Sorgu çalıştırılıyor…</div>
            </section>`;
        }

        if (!data.basarili) {
            return `<section class="vk-layout">
                <div class="vk-head">
                    <h3>Veri Kalitesi Kuralları</h3>
                    <p>Kaynak: <code>${escapeHtml(sqlDosya)}</code> · Katman: ${escapeHtml(katman)}</p>
                </div>
                <div class="vk-error" role="alert">${escapeHtml(data.hata || 'Sorgu başarısız.')}</div>
                <div class="vk-card vk-empty">Kurallar listelenemedi. Sorgu dosyasını ve bağlantı ayarlarını kontrol edin.</div>
            </section>`;
        }

        const cols = data.kolonlar || [];
        const rows = data.satirlar || [];
        const activeCount = rows.filter(r => {
            const flag = r.ActiveFlag;
            return flag === 1 || flag === true || String(flag).toLowerCase() === 'true';
        }).length;

        let meta = `${data.satirSayisi ?? rows.length} kural`;
        if (data.sureMs != null) meta += ` · ${data.sureMs} ms`;
        if (data.kisitlandi) meta += ` · ilk ${data.maxSatir} satır`;

        return `<section class="vk-layout">
            <div class="vk-head">
                <h3>Veri Kalitesi Kuralları</h3>
                <p>TDUTIL <code>DQ.Rule</code> tablosundan canlı kural listesi</p>
            </div>
            <div class="vk-card">
                <div class="vk-card-head">
                    <h4>Kural Listesi</h4>
                    <span>${meta} · ${activeCount} aktif</span>
                </div>
                <p class="vk-hint">Sorgu dosyası: <code>${escapeHtml(sqlDosya)}</code> · Bağlantı: <code>config/td-connections.json</code> (${escapeHtml(katman)})</p>
                <div class="vk-scroll">
                    ${buildResultTable(cols, rows, formatKurallarCell, VK_COLUMN_LABELS)}
                </div>
            </div>
        </section>`;
    }

    function buildGunlukSonuclarHTML() {
        const data = vkGunlukSorgu;

        if (!data) {
            return `<section class="vk-layout">
                <div class="vk-head">
                    <h3>Günlük Kural Sonuçları</h3>
                    <p>Bugünkü başarısız kural sonuçları yükleniyor…</p>
                </div>
                <div class="vk-card vk-loading">Sonuçlar getiriliyor…</div>
            </section>`;
        }

        if (!data.basarili) {
            return `<section class="vk-layout">
                <div class="vk-head">
                    <h3>Günlük Kural Sonuçları</h3>
                    <p>Bugünkü başarısız kural kayıtları</p>
                </div>
                <div class="vk-error" role="alert">${escapeHtml(data.hata || 'Sonuçlar alınamadı.')}</div>
                <div class="vk-card vk-empty">Günlük sonuçlar listelenemedi.</div>
            </section>`;
        }

        const cols = data.kolonlar || [];
        const rows = data.satirlar || [];

        let meta = `${data.satirSayisi ?? rows.length} kayıt`;
        if (data.sureMs != null) meta += ` · ${data.sureMs} ms`;
        if (data.kisitlandi) meta += ` · ilk ${data.maxSatir} satır gösterildi`;

        const today = new Date().toLocaleDateString('tr-TR');

        return `<section class="vk-layout">
            <div class="vk-head">
                <h3>Günlük Kural Sonuçları</h3>
                <p>Bugün (${today}) başarısız olan aktif kurallar</p>
            </div>
            <div class="vk-card">
                <div class="vk-card-head">
                    <h4>Başarısız Sonuçlar</h4>
                    <span>${meta}</span>
                </div>
                <div class="vk-scroll">
                    ${buildResultTable(cols, rows, formatGunlukCell, GUNLUK_COLUMN_LABELS)}
                </div>
            </div>
        </section>`;
    }

    async function initVkPage(type, container) {
        const el = container || document.querySelector('[data-vk-page]') || document.getElementById('pageBody');
        if (!el) return;

        if (type === 'gunluk') {
            el.innerHTML = buildGunlukSonuclarHTML();
            await loadVkGunlukSorgu();
            el.innerHTML = buildGunlukSonuclarHTML();
            return;
        }

        el.innerHTML = buildKurallarHTML();
        await loadVkKurallarSorgu();
        el.innerHTML = buildKurallarHTML();
    }

    window.buildVeriKalitesiKurallariHTML = buildKurallarHTML;
    window.buildGunlukKuralSonuclariHTML = buildGunlukSonuclarHTML;
    window.initVeriKalitesiKurallariPage = (c) => initVkPage('kurallar', c);
    window.initGunlukKuralSonuclariPage = (c) => initVkPage('gunluk', c);

    document.addEventListener('DOMContentLoaded', () => {
        const host = document.querySelector('[data-vk-page]');
        if (!host) return;
        initVkPage(host.dataset.vkPage, host);
    });
})();
