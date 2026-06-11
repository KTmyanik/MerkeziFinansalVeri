(function () {
    const KATMAN_ROL = {
        TDSTG: 'Staging — ham veri katmanı',
        TDMAIN: 'Ana veri — kurumsal çekirdek',
        TDREPORT: 'Raporlama — analitik katman'
    };

    const KATMAN_TEMA = {
        TDSTG: 'stg',
        TDMAIN: 'main',
        TDREPORT: 'report'
    };

    let veriKaynaklari = [];
    let currentKaynakId = null;

    async function loadVeriKaynaklari() {
        try {
            veriKaynaklari = await ApiClient.getVeriKaynaklari();
            if (veriKaynaklari.length && !currentKaynakId) {
                currentKaynakId = veriKaynaklari[0].kaynakId;
            }
        } catch (err) {
            console.error('Veri kaynakları yüklenemedi:', err);
            veriKaynaklari = [];
        }
    }

    function getKaynak(id) {
        return veriKaynaklari.find(v => v.kaynakId === id) || veriKaynaklari[0];
    }

    function statusLabel(status) {
        if (status === 'connected') return 'Bağlı';
        if (status === 'error') return 'Hata';
        if (status === 'unknown') return 'Yapılandırılmadı';
        return 'Yapılandırılmadı';
    }

    function statusClass(status) {
        if (status === 'connected') return 'connected';
        if (status === 'error') return 'error';
        return '';
    }

    function buildDbOptions(selectedId) {
        return veriKaynaklari.map(v => {
            const label = `${v.katmanKodu} — ${statusLabel(v.durum)}`;
            return `<option value="${v.kaynakId}" ${v.kaynakId === selectedId ? 'selected' : ''}>${label}</option>`;
        }).join('');
    }

    function buildPageHTML(selectedId) {
        const kaynak = getKaynak(selectedId);
        if (!kaynak) {
            return `<div class="dbc-layout"><p>API bağlantısı kurulamadı. Sunucunun çalıştığından emin olun.</p></div>`;
        }

        const tema = KATMAN_TEMA[kaynak.katmanKodu] || 'main';
        const rol = KATMAN_ROL[kaynak.katmanKodu] || kaynak.katmanKodu;
        const showSqlUser = kaynak.kimlikDogrulama === 'sql';

        return `<div class="dbc-layout">
            <article class="dbc-panel theme-${tema}" data-dbc-panel>
                <div class="dbc-panel-head">
                    <div>
                        <h3><i class="ti ti-plug-connected" aria-hidden="true"></i> Veritabanı Bağlantısı</h3>
                        <p>TDSTG, TDMAIN ve TDREPORT ortamları için bağlantı parametrelerini yönetin.</p>
                    </div>
                    <span class="dbc-status ${statusClass(kaynak.durum)}" data-status>${statusLabel(kaynak.durum)}</span>
                </div>
                <div class="dbc-panel-body">
                    <div class="dbc-field">
                        <label for="dbc-db-select">Veritabanı Seçimi</label>
                        <select id="dbc-db-select" data-db-select>${buildDbOptions(kaynak.kaynakId)}</select>
                        <p class="dbc-db-role" data-db-role>${rol}</p>
                    </div>
                    <div class="dbc-field">
                        <label for="dbc-server">Sunucu</label>
                        <input type="text" id="dbc-server" data-field="server" value="${escapeHtml(kaynak.sunucu)}" placeholder="10.13.8.238 veya sql-server.sirket.local">
                    </div>
                    <div class="dbc-row">
                        <div class="dbc-field">
                            <label for="dbc-database">Veritabanı</label>
                            <input type="text" id="dbc-database" data-field="database" value="${escapeHtml(kaynak.veritabani)}">
                        </div>
                        <div class="dbc-field">
                            <label for="dbc-port">Port</label>
                            <input type="text" id="dbc-port" data-field="port" value="${kaynak.port || 1433}">
                        </div>
                    </div>
                    <div class="dbc-field">
                        <label for="dbc-auth">Kimlik Doğrulama</label>
                        <select id="dbc-auth" data-field="auth">
                            <option value="sql" ${kaynak.kimlikDogrulama === 'sql' ? 'selected' : ''}>SQL Server</option>
                            <option value="windows" ${kaynak.kimlikDogrulama === 'windows' ? 'selected' : ''}>Windows (Entegre)</option>
                        </select>
                    </div>
                    <div class="dbc-field" data-sql-user-wrap style="${showSqlUser ? '' : 'display:none'}">
                        <label for="dbc-sql-user">SQL Kullanıcı Adı</label>
                        <input type="text" id="dbc-sql-user" data-field="sqlUser" value="${escapeHtml(kaynak.kullaniciAdi || '')}" placeholder="sa veya uygulama kullanıcısı">
                    </div>
                    <p class="dbc-test-msg" data-test-msg role="status" hidden></p>
                    <div class="dbc-actions">
                        <button type="button" class="dbc-test-btn" data-test>Bağlantıyı Test Et</button>
                        <button type="button" class="dbc-save-btn" data-save>Kaydet</button>
                    </div>
                </div>
            </article>
            <p class="dbc-hint">Bağlantı bilgileri sunucu tarafında (cfg.VeriKaynagi) saklanır. appsettings.json içindeki TdConnections değerleri ilk yüklemede varsayılan olarak uygulanır.</p>
            <div class="dbc-footer">
                <span class="dbc-footer-msg" id="dbcSaveMsg" role="status">Kaydedildi</span>
            </div>
        </div>`;
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function readFormFields(scope) {
        const data = {};
        scope.querySelectorAll('[data-field]').forEach(el => {
            const key = el.dataset.field;
            if (key === 'database') data.veritabani = el.value.trim();
            else if (key === 'server') data.sunucu = el.value.trim();
            else if (key === 'port') data.port = parseInt(el.value.trim(), 10) || 1433;
            else if (key === 'auth') data.kimlikDogrulama = el.value.trim();
            else if (key === 'sqlUser') data.kullaniciAdi = el.value.trim() || null;
        });
        return data;
    }

    function updateStatus(scope, status) {
        const badge = scope.querySelector('[data-status]');
        if (!badge) return;
        badge.className = 'dbc-status ' + statusClass(status);
        badge.textContent = statusLabel(status);
    }

    function showTestMsg(scope, message, isError) {
        const el = scope.querySelector('[data-test-msg]');
        if (!el) return;
        el.hidden = !message;
        el.textContent = message || '';
        el.classList.toggle('error', !!isError);
        el.classList.toggle('success', !!message && !isError);
    }

    function toggleSqlUserField(scope) {
        const auth = scope.querySelector('[data-field="auth"]')?.value;
        const wrap = scope.querySelector('[data-sql-user-wrap]');
        if (wrap) wrap.style.display = auth === 'sql' ? '' : 'none';
    }

    function bindEvents(root) {
        const scope = root || document;
        let currentId = parseInt(scope.querySelector('[data-db-select]')?.value, 10) || currentKaynakId;

        scope.querySelector('[data-db-select]')?.addEventListener('change', (e) => {
            currentId = parseInt(e.target.value, 10);
            currentKaynakId = currentId;
            const kaynak = getKaynak(currentId);
            scope.querySelector('[data-field="server"]').value = kaynak.sunucu || '';
            scope.querySelector('[data-field="database"]').value = kaynak.veritabani || '';
            scope.querySelector('[data-field="port"]').value = kaynak.port || 1433;
            scope.querySelector('[data-field="auth"]').value = kaynak.kimlikDogrulama || 'windows';
            const sqlUser = scope.querySelector('[data-field="sqlUser"]');
            if (sqlUser) sqlUser.value = kaynak.kullaniciAdi || '';
            updateStatus(scope, kaynak.durum);
            toggleSqlUserField(scope);
            showTestMsg(scope, '', false);
            const panel = scope.querySelector('[data-dbc-panel]');
            if (panel) panel.className = `dbc-panel theme-${KATMAN_TEMA[kaynak.katmanKodu] || 'main'}`;
            const roleEl = scope.querySelector('[data-db-role]');
            if (roleEl) roleEl.textContent = KATMAN_ROL[kaynak.katmanKodu] || kaynak.katmanKodu;
        });

        scope.querySelector('[data-field="auth"]')?.addEventListener('change', () => {
            toggleSqlUserField(scope);
        });

        scope.querySelector('[data-test]')?.addEventListener('click', async (btn) => {
            const button = btn.currentTarget;
            const formData = readFormFields(scope);
            if (!formData.sunucu || !formData.veritabani) {
                showTestMsg(scope, 'Sunucu ve veritabanı alanları zorunludur.', true);
                return;
            }

            button.disabled = true;
            button.textContent = 'Test ediliyor…';
            showTestMsg(scope, '', false);

            try {
                const result = await ApiClient.testVeriKaynagi(currentId, formData);
                const status = result.basarili ? 'connected' : 'error';
                updateStatus(scope, status);
                showTestMsg(scope, result.mesaj || (result.basarili ? 'Bağlantı başarılı.' : 'Bağlantı başarısız.'), !result.basarili);

                const idx = veriKaynaklari.findIndex(v => v.kaynakId === currentId);
                if (idx >= 0) veriKaynaklari[idx].durum = status;
                scope.querySelector('[data-db-select]').innerHTML = buildDbOptions(currentId);
            } catch (err) {
                updateStatus(scope, 'error');
                showTestMsg(scope, 'Test isteği başarısız: ' + err.message, true);
                console.error('Bağlantı testi başarısız:', err);
            }

            button.disabled = false;
            button.textContent = 'Bağlantıyı Test Et';
        });

        scope.querySelector('[data-save]')?.addEventListener('click', async () => {
            const formData = readFormFields(scope);
            if (!formData.sunucu || !formData.veritabani) {
                showTestMsg(scope, 'Kaydetmeden önce sunucu ve veritabanı girin.', true);
                return;
            }

            try {
                const updated = await ApiClient.updateVeriKaynagi(currentId, formData);
                const idx = veriKaynaklari.findIndex(v => v.kaynakId === currentId);
                if (idx >= 0) veriKaynaklari[idx] = { ...veriKaynaklari[idx], ...updated };
                showSaveMsg(scope);
                showTestMsg(scope, 'Ayarlar kaydedildi. Bağlantıyı test edebilirsiniz.', false);
            } catch (err) {
                alert('Kaydetme başarısız: ' + err.message);
            }
        });
    }

    function showSaveMsg(root) {
        const msg = (root || document).querySelector('#dbcSaveMsg');
        if (!msg) return;
        msg.classList.add('visible');
        clearTimeout(showSaveMsg._timer);
        showSaveMsg._timer = setTimeout(() => msg.classList.remove('visible'), 2200);
    }

    async function initVeritabaniBaglantisi(container) {
        await loadVeriKaynaklari();
        const root = container || document;
        if (root === document && !root.querySelector('.dbc-layout')) {
            const pageBody = root.querySelector('.page-body');
            if (pageBody) {
                pageBody.innerHTML = buildPageHTML(currentKaynakId);
                bindEvents(pageBody);
            }
            return;
        }
        if (!root.querySelector('.dbc-layout')) {
            root.innerHTML = buildPageHTML(currentKaynakId);
        }
        bindEvents(root);
    }

    window.buildVeritabaniBaglantisiHTML = buildPageHTML;
    window.initVeritabaniBaglantisi = initVeritabaniBaglantisi;

    document.addEventListener('DOMContentLoaded', () => {
        const host = document.querySelector('[data-db-page]');
        if (host) {
            initVeritabaniBaglantisi(host);
            return;
        }
        if (document.querySelector('.dbc-layout')) {
            initVeritabaniBaglantisi(document);
        }
    });
})();
