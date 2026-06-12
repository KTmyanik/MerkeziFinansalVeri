(function () {
    const DEFAULT_BASE = 'http://localhost:5038/api';

    function getBaseUrl() {
        return (localStorage.getItem('apiBaseUrl') || DEFAULT_BASE).replace(/\/$/, '');
    }

    function getUserId() {
        const stored = localStorage.getItem('currentUserId');
        if (stored) return parseInt(stored, 10);
        return 9;
    }

    function getUserRole() {
        return localStorage.getItem('userRole') || 'admin';
    }

    async function request(path, options = {}) {
        const url = `${getBaseUrl()}${path.startsWith('/') ? path : `/${path}`}`;
        const headers = {
            Accept: 'application/json',
            'X-User-Id': String(getUserId()),
            ...(options.headers || {})
        };

        if (options.body && !(options.body instanceof FormData)) {
            headers['Content-Type'] = 'application/json';
            options.body = JSON.stringify(options.body);
        }

        const response = await fetch(url, { ...options, headers });

        if (!response.ok) {
            let detail = response.statusText;
            try {
                const err = await response.json();
                detail = err.title || err.detail || err.message || detail;
            } catch { /* ignore */ }
            throw new Error(detail || `HTTP ${response.status}`);
        }

        if (response.status === 204) return null;

        const text = await response.text();
        return text ? JSON.parse(text) : null;
    }

    const api = {
        get baseUrl() { return getBaseUrl(); },
        get userId() { return getUserId(); },
        get userRole() { return getUserRole(); },

        get: (path) => request(path),
        post: (path, body) => request(path, { method: 'POST', body }),
        put: (path, body) => request(path, { method: 'PUT', body }),
        delete: (path) => request(path, { method: 'DELETE' }),

        // Kurumsal Hesaplar
        getKurumsalHesaplar(params = {}) {
            const q = new URLSearchParams();
            if (params.hesapAdi) q.set('hesapAdi', params.hesapAdi);
            if (params.ekipAdi) q.set('ekipAdi', params.ekipAdi);
            if (params.ekip) q.set('ekip', params.ekip);
            if (params.hesapIdMin != null) q.set('hesapIdMin', params.hesapIdMin);
            if (params.hesapIdMax != null) q.set('hesapIdMax', params.hesapIdMax);
            const qs = q.toString();
            return request(`/kurumsal-hesaplar${qs ? `?${qs}` : ''}`);
        },
        createKurumsalHesap(data) { return request('/kurumsal-hesaplar', { method: 'POST', body: data }); },
        updateKurumsalHesap(hesapNo, data) { return request(`/kurumsal-hesaplar/${hesapNo}`, { method: 'PUT', body: data }); },
        deleteKurumsalHesap(hesapNo) { return request(`/kurumsal-hesaplar/${hesapNo}`, { method: 'DELETE' }); },

        // Kullanıcı / Rol
        getKullanicilar() { return request('/kullanicilar'); },
        getKullanici(id) { return request(`/kullanicilar/${id}`); },
        updateKullanici(id, data) { return request(`/kullanicilar/${id}`, { method: 'PUT', body: data }); },
        getKullaniciYetkiler(id) { return request(`/kullanicilar/${id}/yetkiler`); },
        updateKullaniciYetkiler(id, yetkiler) { return request(`/kullanicilar/${id}/yetkiler`, { method: 'PUT', body: yetkiler }); },
        sifirlaKullaniciYetkiler(id) { return request(`/kullanicilar/${id}/yetkiler/sifirla`, { method: 'POST' }); },
        getRoller() { return request('/roller'); },
        getRolYetkiler(rolId) { return request(`/roller/${rolId}/yetkiler`); },

        // Mutabakat
        getMutabakatDonemler() { return request('/mutabakat/donemler'); },
        setAktifDonem(donemId) { return request('/mutabakat/donemler/aktif', { method: 'PUT', body: { donemId } }); },
        getFarkVeren(params = {}) {
            const q = new URLSearchParams();
            if (params.donemId) q.set('donemId', params.donemId);
            if (params.ekip) q.set('ekip', params.ekip);
            if (params.durum) q.set('durum', params.durum);
            if (params.hesapKodu) q.set('hesapKodu', params.hesapKodu);
            const qs = q.toString();
            return request(`/mutabakat/fark-veren${qs ? `?${qs}` : ''}`);
        },

        // Süreç / Mizan
        getSurecKokpit() { return request('/surec/kokpit'); },
        getSurecDomainler() { return request('/surec/domainler'); },
        getSurecGorevler(params = {}) {
            const q = new URLSearchParams();
            if (params.datasetId) q.set('datasetId', params.datasetId);
            if (params.donemId) q.set('donemId', params.donemId);
            const qs = q.toString();
            return request(`/surec/gorevler${qs ? `?${qs}` : ''}`);
        },
        getTaskListesi() { return request('/surec/task-listesi'); },
        getMizanGorevler() { return request('/mizan/gorevler'); },
        yenidenBaslatMizanGorev(gorevTanimId) {
            return request('/mizan/gorevler/yeniden-baslat', { method: 'POST', body: { gorevTanimId } });
        },

        // Portal / VK / Aktivite
        getPortalOzet() { return request('/portal/ozet'); },
        getVkKurallar() { return request('/veri-kalitesi/kurallar'); },
        getVkKurallarAyarlar() { return request('/veri-kalitesi/kurallar/ayarlar'); },
        getVkKurallarSorgu() { return request('/veri-kalitesi/kurallar/sorgu'); },
        getVkGunlukSonuclar(tarih) {
            const q = tarih ? `?tarih=${tarih}` : '';
            return request(`/veri-kalitesi/gunluk-sonuclar${q}`);
        },
        getAktiviteLog(limit = 20) { return request(`/aktivite-log?limit=${limit}`); },

        // Veri Kaynakları
        getVeriKaynaklari() { return request('/veri-kaynaklari'); },
        updateVeriKaynagi(id, data) { return request(`/veri-kaynaklari/${id}`, { method: 'PUT', body: data }); },
        testVeriKaynagi(id, connectionParams) {
            return request(`/veri-kaynaklari/${id}/test`, {
                method: 'POST',
                body: connectionParams || null
            });
        },

        // Veritabanı Sorgusu
        getVeritabaniSorguAyarlar() { return request('/veritabani-sorgu/ayarlar'); },
        calistirVeritabaniSorgu(data) {
            return request('/veritabani-sorgu/calistir', { method: 'POST', body: data });
        },
        testVeritabaniSorguKatman(katmanKodu) {
            return request(`/veritabani-sorgu/test/${encodeURIComponent(katmanKodu)}`, { method: 'POST' });
        }
    };

    window.ApiClient = api;
})();
