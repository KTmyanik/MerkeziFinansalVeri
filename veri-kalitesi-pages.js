(function () {
    let DAILY_RESULTS = [];
    let vkKurallarAyarlar = null;
    let vkKurallarSorgu = null;

    const STATUS_BADGE = {
        ok: { class: 'ok', label: 'Başarılı' },
        warn: { class: 'warn', label: 'Uyarı' },
        fail: { class: 'fail', label: 'Hata' }
    };

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

    function escapeHtml(str) {
        return String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function columnLabel(col) {
        return VK_COLUMN_LABELS[col] || col;
    }

    function formatCell(col, val) {
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

    async function loadGunlukSonuclar() {
        try {
            DAILY_RESULTS = await ApiClient.getVkGunlukSonuclar();
        } catch (err) {
            console.error('Günlük sonuçlar yüklenemedi:', err);
            DAILY_RESULTS = [];
        }
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
            vkKurallarSorgu = {
                basarili: false,
                hata: apiErrorMessage(err)
            };
        }
    }

    function apiErrorMessage(err) {
        const msg = err?.message || String(err);
        if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
            return `API'ye ulaşılamıyor. start-api.bat çalıştırın. Varsayılan: ${ApiClient.baseUrl}`;
        }
        return msg;
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

        const headerCells = cols.map(c => `<th>${escapeHtml(columnLabel(c))}</th>`).join('');
        const bodyRows = rows.map(row => {
            const cells = cols.map(col => {
                const display = formatCell(col, row[col]);
                const title = row[col] === null || row[col] === undefined ? '' : String(row[col]);
                return `<td title="${escapeHtml(title)}">${display}</td>`;
            }).join('');
            return `<tr>${cells}</tr>`;
        }).join('');

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
                    <table class="vk-table">
                        <thead><tr>${headerCells}</tr></thead>
                        <tbody>${bodyRows || '<tr><td colspan="' + cols.length + '">Kayıt bulunamadı.</td></tr>'}</tbody>
                    </table>
                </div>
            </div>
        </section>`;
    }

    function buildGunlukSonuclarHTML() {
        const rows = DAILY_RESULTS.map(r => {
            const badge = STATUS_BADGE[r.sonuc] || { class: '', label: r.sonuc };
            return `
            <tr>
                <td>${r.calistirmaTarihi}</td>
                <td>${r.kuralId}</td>
                <td>${r.kuralAdi}</td>
                <td>${r.gecenSayi}</td>
                <td>${r.hataliSayi}</td>
                <td><span class="vk-badge ${badge.class}">${badge.label}</span></td>
            </tr>`;
        }).join('');

        return `<section class="vk-layout">
            <div class="vk-head">
                <h3>Günlük Kural Sonuçları</h3>
                <p>Kuralların günlük çalışma özeti ve hata sayıları</p>
            </div>
            <div class="vk-card">
                <div class="vk-card-head">
                    <h4>Son Çalıştırmalar</h4>
                    <span>Son 2 gün</span>
                </div>
                <div class="vk-scroll">
                    <table class="vk-table">
                        <thead>
                            <tr>
                                <th>Tarih</th>
                                <th>Kural Kodu</th>
                                <th>Kural Adı</th>
                                <th>Geçen</th>
                                <th>Hatalı</th>
                                <th>Sonuç</th>
                            </tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                </div>
            </div>
        </section>`;
    }

    async function initVkPage(type, container) {
        const el = container || document.querySelector('[data-vk-page]') || document.getElementById('pageBody');
        if (!el) return;

        if (type === 'gunluk') {
            await loadGunlukSonuclar();
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
