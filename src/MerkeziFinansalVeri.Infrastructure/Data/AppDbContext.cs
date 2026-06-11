using MerkeziFinansalVeri.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MerkeziFinansalVeri.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Ekip> Ekipler => Set<Ekip>();
    public DbSet<Sayfa> Sayfalar => Set<Sayfa>();
    public DbSet<VeriKatmani> VeriKatmanlari => Set<VeriKatmani>();
    public DbSet<VeriDomain> VeriDomainleri => Set<VeriDomain>();
    public DbSet<Rol> Roller => Set<Rol>();
    public DbSet<Kullanici> Kullanicilar => Set<Kullanici>();
    public DbSet<RolSayfaYetki> RolSayfaYetkileri => Set<RolSayfaYetki>();
    public DbSet<KullaniciSayfaYetki> KullaniciSayfaYetkileri => Set<KullaniciSayfaYetki>();
    public DbSet<VeriKaynagi> VeriKaynaklari => Set<VeriKaynagi>();
    public DbSet<SistemParametre> SistemParametreleri => Set<SistemParametre>();
    public DbSet<KurumsalHesap> KurumsalHesaplar => Set<KurumsalHesap>();
    public DbSet<MutabakatDonem> MutabakatDonemleri => Set<MutabakatDonem>();
    public DbSet<FarkVerenHesap> FarkVerenHesaplar => Set<FarkVerenHesap>();
    public DbSet<SurecDataset> SurecDatasetleri => Set<SurecDataset>();
    public DbSet<SurecGorevTanim> SurecGorevTanimlari => Set<SurecGorevTanim>();
    public DbSet<SurecGorevDurum> SurecGorevDurumlari => Set<SurecGorevDurum>();
    public DbSet<SurecGorevYenidenBaslatmaLog> SurecGorevYenidenBaslatmaLoglari => Set<SurecGorevYenidenBaslatmaLog>();
    public DbSet<VeriKalitesiKural> VeriKalitesiKurallari => Set<VeriKalitesiKural>();
    public DbSet<VeriKalitesiKuralSonuc> VeriKalitesiKuralSonuclari => Set<VeriKalitesiKuralSonuc>();
    public DbSet<KayitliSorgu> KayitliSorgular => Set<KayitliSorgu>();
    public DbSet<RaporTanim> RaporTanimlari => Set<RaporTanim>();
    public DbSet<RaporSonucSnapshot> RaporSonucSnapshotlari => Set<RaporSonucSnapshot>();
    public DbSet<AktiviteLog> AktiviteLoglari => Set<AktiviteLog>();
    public DbSet<SorguCalistirmaLog> SorguCalistirmaLoglari => Set<SorguCalistirmaLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Ekip>(entity =>
        {
            entity.ToTable("ref_Team", "VIB");
            entity.HasKey(e => e.EkipId);
            entity.Property(e => e.EkipId).HasColumnName("TeamId");
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(100);
            entity.Property(e => e.Aktif).HasColumnName("IsActive");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
            entity.Property(e => e.SilindiMi).HasColumnName("IsDeleted");
        });

        modelBuilder.Entity<Sayfa>(entity =>
        {
            entity.ToTable("ref_Page", "VIB");
            entity.HasKey(e => e.SayfaId);
            entity.Property(e => e.SayfaId).HasColumnName("PageId").HasMaxLength(50);
            entity.Property(e => e.Bolum).HasColumnName("Section").HasMaxLength(100);
            entity.Property(e => e.BolumIkon).HasColumnName("SectionIcon").HasMaxLength(50);
            entity.Property(e => e.Etiket).HasColumnName("Label").HasMaxLength(200);
            entity.Property(e => e.Href).HasMaxLength(500);
            entity.Property(e => e.Sira).HasColumnName("SortOrder");
        });

        modelBuilder.Entity<VeriKatmani>(entity =>
        {
            entity.ToTable("ref_DataLayer", "VIB");
            entity.HasKey(e => e.KatmanKodu);
            entity.Property(e => e.KatmanKodu).HasColumnName("LayerCode").HasMaxLength(20);
            entity.Property(e => e.Rol).HasColumnName("LayerRole").HasMaxLength(200);
            entity.Property(e => e.Tema).HasColumnName("Theme").HasMaxLength(20);
            entity.Property(e => e.Sira).HasColumnName("SortOrder");
        });

        modelBuilder.Entity<VeriDomain>(entity =>
        {
            entity.ToTable("ref_DataDomain", "VIB");
            entity.HasKey(e => e.DomainId);
            entity.Property(e => e.DomainId).HasMaxLength(50);
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(100);
            entity.Property(e => e.Tema).HasColumnName("Theme").HasMaxLength(20);
            entity.Property(e => e.Sira).HasColumnName("SortOrder");
        });

        modelBuilder.Entity<Rol>(entity =>
        {
            entity.ToTable("sec_Role", "VIB");
            entity.HasKey(e => e.RolId);
            entity.Property(e => e.RolId).HasColumnName("RoleId").HasMaxLength(50);
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(100);
            entity.Property(e => e.Aciklama).HasColumnName("Description").HasMaxLength(500);
            entity.Property(e => e.RozetSinifi).HasColumnName("BadgeClass").HasMaxLength(50);
        });

        modelBuilder.Entity<Kullanici>(entity =>
        {
            entity.ToTable("sec_User", "VIB");
            entity.HasKey(e => e.KullaniciId);
            entity.Property(e => e.KullaniciId).HasColumnName("UserId");
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(200);
            entity.Property(e => e.Eposta).HasColumnName("Email").HasMaxLength(200);
            entity.Property(e => e.RolId).HasColumnName("RoleId").HasMaxLength(50);
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.SonGiris).HasColumnName("LastLoginAt");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
            entity.Property(e => e.SilindiMi).HasColumnName("IsDeleted");
            entity.HasOne(e => e.Rol).WithMany(r => r.Kullanicilar).HasForeignKey(e => e.RolId);
        });

        modelBuilder.Entity<RolSayfaYetki>(entity =>
        {
            entity.ToTable("sec_RolePagePermission", "VIB");
            entity.HasKey(e => new { e.RolId, e.SayfaId });
            entity.Property(e => e.RolId).HasColumnName("RoleId").HasMaxLength(50);
            entity.Property(e => e.SayfaId).HasColumnName("PageId").HasMaxLength(50);
            entity.HasOne(e => e.Rol).WithMany(r => r.RolSayfaYetkileri).HasForeignKey(e => e.RolId);
            entity.HasOne(e => e.Sayfa).WithMany(s => s.RolSayfaYetkileri).HasForeignKey(e => e.SayfaId);
        });

        modelBuilder.Entity<KullaniciSayfaYetki>(entity =>
        {
            entity.ToTable("sec_UserPagePermission", "VIB");
            entity.HasKey(e => new { e.KullaniciId, e.SayfaId });
            entity.Property(e => e.KullaniciId).HasColumnName("UserId");
            entity.Property(e => e.SayfaId).HasColumnName("PageId").HasMaxLength(50);
            entity.Property(e => e.IzinVerildi).HasColumnName("IsGranted");
            entity.HasOne(e => e.Kullanici).WithMany(k => k.KullaniciSayfaYetkileri).HasForeignKey(e => e.KullaniciId);
            entity.HasOne(e => e.Sayfa).WithMany(s => s.KullaniciSayfaYetkileri).HasForeignKey(e => e.SayfaId);
        });

        modelBuilder.Entity<VeriKaynagi>(entity =>
        {
            entity.ToTable("cfg_DataSource", "VIB");
            entity.HasKey(e => e.KaynakId);
            entity.Property(e => e.KaynakId).HasColumnName("SourceId");
            entity.Property(e => e.KatmanKodu).HasColumnName("LayerCode").HasMaxLength(20);
            entity.Property(e => e.Sunucu).HasColumnName("ServerName").HasMaxLength(200);
            entity.Property(e => e.Veritabani).HasColumnName("DatabaseName").HasMaxLength(100);
            entity.Property(e => e.KimlikDogrulama).HasColumnName("AuthenticationMode").HasMaxLength(20);
            entity.Property(e => e.KullaniciAdi).HasColumnName("Username").HasMaxLength(100);
            entity.Property(e => e.SifreSaklandi).HasColumnName("IsPasswordStored");
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
            entity.HasOne(e => e.VeriKatmani).WithMany(v => v.VeriKaynaklari).HasForeignKey(e => e.KatmanKodu);
        });

        modelBuilder.Entity<SistemParametre>(entity =>
        {
            entity.ToTable("cfg_SystemParameter", "VIB");
            entity.HasKey(e => e.Anahtar);
            entity.Property(e => e.Anahtar).HasColumnName("ParameterKey").HasMaxLength(100);
            entity.Property(e => e.Deger).HasColumnName("ParameterValue").HasMaxLength(500);
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
        });

        modelBuilder.Entity<KurumsalHesap>(entity =>
        {
            entity.ToTable("ops_CorporateAccount", "VIB");
            entity.HasKey(e => e.HesapNo);
            entity.Property(e => e.HesapNo).HasColumnName("AccountNo");
            entity.Property(e => e.HesapId).HasColumnName("AccountId");
            entity.HasIndex(e => e.HesapId).IsUnique();
            entity.Property(e => e.HesapAdi).HasColumnName("AccountName").HasMaxLength(200);
            entity.Property(e => e.EkipId).HasColumnName("TeamId");
            entity.Property(e => e.BeklenenAksiyon).HasColumnName("ExpectedAction").HasMaxLength(100);
            entity.Property(e => e.Kaynak).HasColumnName("Source").HasMaxLength(50);
            entity.Property(e => e.KayitTarihi).HasColumnName("RecordDate");
            entity.Property(e => e.GuncellemeTarihi).HasColumnName("UpdatedAt");
            entity.Property(e => e.OlusturanKullaniciId).HasColumnName("CreatedByUserId");
            entity.Property(e => e.GuncelleyenKullaniciId).HasColumnName("UpdatedByUserId");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.SilindiMi).HasColumnName("IsDeleted");
            entity.HasOne(e => e.Ekip).WithMany(e => e.KurumsalHesaplar).HasForeignKey(e => e.EkipId);
            entity.HasOne(e => e.OlusturanKullanici).WithMany(k => k.OlusturduguKurumsalHesaplar).HasForeignKey(e => e.OlusturanKullaniciId);
            entity.HasOne(e => e.GuncelleyenKullanici).WithMany(k => k.GuncelledigiKurumsalHesaplar).HasForeignKey(e => e.GuncelleyenKullaniciId);
        });

        modelBuilder.Entity<MutabakatDonem>(entity =>
        {
            entity.ToTable("ops_ReconciliationPeriod", "VIB");
            entity.HasKey(e => e.DonemId);
            entity.Property(e => e.DonemId).HasColumnName("PeriodId");
            entity.HasIndex(e => e.YilAy).IsUnique();
            entity.Property(e => e.YilAy).HasColumnName("YearMonth").HasMaxLength(7).IsFixedLength();
            entity.Property(e => e.Etiket).HasColumnName("Label").HasMaxLength(100);
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.HesapSayisi).HasColumnName("AccountCount");
            entity.Property(e => e.FarkVerenSayisi).HasColumnName("VarianceCount");
            entity.Property(e => e.KapanisTarihi).HasColumnName("ClosedDate");
            entity.Property(e => e.AktifMi).HasColumnName("IsActive");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
        });

        modelBuilder.Entity<FarkVerenHesap>(entity =>
        {
            entity.ToTable("ops_VarianceAccount", "VIB");
            entity.HasKey(e => e.FarkId);
            entity.Property(e => e.FarkId).HasColumnName("VarianceId");
            entity.HasIndex(e => new { e.DonemId, e.HesapKodu }).IsUnique();
            entity.Property(e => e.DonemId).HasColumnName("PeriodId");
            entity.Property(e => e.HesapKodu).HasColumnName("AccountCode").HasMaxLength(50);
            entity.Property(e => e.HesapAdi).HasColumnName("AccountName").HasMaxLength(200);
            entity.Property(e => e.EkipId).HasColumnName("TeamId");
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.MizanBakiye).HasColumnName("TrialBalanceAmount").HasColumnType("decimal(18,2)");
            entity.Property(e => e.KartonBakiye).HasColumnName("CardTableAmount").HasColumnType("decimal(18,2)");
            entity.Property(e => e.Fark)
                .HasColumnName("VarianceAmount")
                .HasColumnType("decimal(18,2)")
                .HasComputedColumnSql("(TrialBalanceAmount - CardTableAmount)", stored: true);
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
            entity.Property(e => e.SilindiMi).HasColumnName("IsDeleted");
            entity.HasOne(e => e.Donem).WithMany(d => d.FarkVerenHesaplar).HasForeignKey(e => e.DonemId);
            entity.HasOne(e => e.Ekip).WithMany(e => e.FarkVerenHesaplar).HasForeignKey(e => e.EkipId);
        });

        modelBuilder.Entity<SurecDataset>(entity =>
        {
            entity.ToTable("ops_ProcessDataset", "VIB");
            entity.HasKey(e => e.DatasetId);
            entity.HasIndex(e => e.Kod).IsUnique();
            entity.Property(e => e.Kod).HasColumnName("Code").HasMaxLength(50);
            entity.Property(e => e.Etiket).HasColumnName("Label").HasMaxLength(200);
            entity.Property(e => e.KatmanKodu).HasColumnName("LayerCode").HasMaxLength(20);
            entity.Property(e => e.DomainId).HasMaxLength(50);
            entity.Property(e => e.Sira).HasColumnName("SortOrder");
            entity.HasOne(e => e.VeriKatmani).WithMany(v => v.SurecDatasetler).HasForeignKey(e => e.KatmanKodu);
            entity.HasOne(e => e.VeriDomain).WithMany(v => v.SurecDatasetler).HasForeignKey(e => e.DomainId);
        });

        modelBuilder.Entity<SurecGorevTanim>(entity =>
        {
            entity.ToTable("ops_ProcessTaskDefinition", "VIB");
            entity.HasKey(e => e.GorevTanimId);
            entity.Property(e => e.GorevTanimId).HasColumnName("TaskDefinitionId");
            entity.Property(e => e.Etiket).HasColumnName("Label").HasMaxLength(100);
            entity.Property(e => e.Sira).HasColumnName("SortOrder");
            entity.HasOne(e => e.Dataset).WithMany(d => d.SurecGorevTanimlari).HasForeignKey(e => e.DatasetId);
        });

        modelBuilder.Entity<SurecGorevDurum>(entity =>
        {
            entity.ToTable("ops_ProcessTaskStatus", "VIB");
            entity.HasKey(e => e.GorevDurumId);
            entity.Property(e => e.GorevDurumId).HasColumnName("TaskStatusId");
            entity.Property(e => e.GorevTanimId).HasColumnName("TaskDefinitionId");
            entity.Property(e => e.DonemId).HasColumnName("PeriodId");
            entity.HasIndex(e => new { e.GorevTanimId, e.DonemId }).IsUnique();
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.SonGuncelleme).HasColumnName("LastUpdatedAt");
            entity.HasOne(e => e.GorevTanim).WithMany(g => g.SurecGorevDurumlari).HasForeignKey(e => e.GorevTanimId);
            entity.HasOne(e => e.Donem).WithMany(d => d.SurecGorevDurumlari).HasForeignKey(e => e.DonemId);
        });

        modelBuilder.Entity<SurecGorevYenidenBaslatmaLog>(entity =>
        {
            entity.ToTable("ops_ProcessTaskRestartLog", "VIB");
            entity.HasKey(e => e.LogId);
            entity.Property(e => e.GorevTanimId).HasColumnName("TaskDefinitionId");
            entity.Property(e => e.KullaniciId).HasColumnName("UserId");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.HasOne(e => e.GorevTanim).WithMany(g => g.YenidenBaslatmaLoglari).HasForeignKey(e => e.GorevTanimId);
            entity.HasOne(e => e.Kullanici).WithMany(k => k.SurecGorevYenidenBaslatmaLoglari).HasForeignKey(e => e.KullaniciId);
        });

        modelBuilder.Entity<VeriKalitesiKural>(entity =>
        {
            entity.ToTable("ops_DataQualityRule", "VIB");
            entity.HasKey(e => e.KuralId);
            entity.Property(e => e.KuralId).HasColumnName("RuleId").HasMaxLength(20);
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(200);
            entity.Property(e => e.Alan).HasColumnName("Domain").HasMaxLength(100);
            entity.Property(e => e.Onem).HasColumnName("Severity").HasMaxLength(20);
            entity.Property(e => e.Durum).HasColumnName("Status").HasMaxLength(20);
            entity.Property(e => e.SqlIfade).HasColumnName("SqlExpression");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.Property(e => e.GuncellemeZamani).HasColumnName("UpdatedAt");
        });

        modelBuilder.Entity<VeriKalitesiKuralSonuc>(entity =>
        {
            entity.ToTable("ops_DataQualityRuleResult", "VIB");
            entity.HasKey(e => e.SonucId);
            entity.Property(e => e.SonucId).HasColumnName("ResultId");
            entity.Property(e => e.CalistirmaTarihi).HasColumnName("ExecutionDate");
            entity.Property(e => e.KuralId).HasColumnName("RuleId").HasMaxLength(20);
            entity.Property(e => e.GecenSayi).HasColumnName("PassedCount");
            entity.Property(e => e.HataliSayi).HasColumnName("FailedCount");
            entity.Property(e => e.Sonuc).HasColumnName("Result").HasMaxLength(20);
            entity.HasOne(e => e.Kural).WithMany(k => k.KuralSonuclari).HasForeignKey(e => e.KuralId);
        });

        modelBuilder.Entity<KayitliSorgu>(entity =>
        {
            entity.ToTable("ops_SavedQuery", "VIB");
            entity.HasKey(e => e.SorguId);
            entity.Property(e => e.SorguId).HasColumnName("QueryId");
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(200);
            entity.Property(e => e.KatmanKodu).HasColumnName("LayerCode").HasMaxLength(20);
            entity.Property(e => e.SqlMetin).HasColumnName("SqlText");
            entity.Property(e => e.OlusturanKullaniciId).HasColumnName("CreatedByUserId");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.HasOne(e => e.OlusturanKullanici).WithMany(k => k.KayitliSorgular).HasForeignKey(e => e.OlusturanKullaniciId);
        });

        modelBuilder.Entity<RaporTanim>(entity =>
        {
            entity.ToTable("ops_ReportDefinition", "VIB");
            entity.HasKey(e => e.RaporKodu);
            entity.Property(e => e.RaporKodu).HasColumnName("ReportCode").HasMaxLength(50);
            entity.Property(e => e.Ad).HasColumnName("Name").HasMaxLength(200);
            entity.Property(e => e.KaynakKatman).HasColumnName("SourceLayer").HasMaxLength(20);
            entity.Property(e => e.ViewAdi).HasColumnName("ViewName").HasMaxLength(200);
            entity.Property(e => e.SpAdi).HasColumnName("StoredProcedureName").HasMaxLength(200);
        });

        modelBuilder.Entity<RaporSonucSnapshot>(entity =>
        {
            entity.ToTable("ops_ReportResultSnapshot", "VIB");
            entity.HasKey(e => e.SnapshotId);
            entity.Property(e => e.RaporKodu).HasColumnName("ReportCode").HasMaxLength(50);
            entity.Property(e => e.DonemId).HasColumnName("PeriodId");
            entity.Property(e => e.JsonSonuc).HasColumnName("ResultJson");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.HasOne(e => e.RaporTanim).WithMany(r => r.RaporSonucSnapshotlari).HasForeignKey(e => e.RaporKodu);
            entity.HasOne(e => e.Donem).WithMany(d => d.RaporSonucSnapshotlari).HasForeignKey(e => e.DonemId);
        });

        modelBuilder.Entity<AktiviteLog>(entity =>
        {
            entity.ToTable("audit_ActivityLog", "VIB");
            entity.HasKey(e => e.LogId);
            entity.Property(e => e.OlayTipi).HasColumnName("EventType").HasMaxLength(50);
            entity.Property(e => e.Baslik).HasColumnName("Title").HasMaxLength(200);
            entity.Property(e => e.Detay).HasColumnName("Detail").HasMaxLength(500);
            entity.Property(e => e.KullaniciId).HasColumnName("UserId");
            entity.Property(e => e.OlusturmaZamani).HasColumnName("CreatedAt");
            entity.HasOne(e => e.Kullanici).WithMany(k => k.AktiviteLoglari).HasForeignKey(e => e.KullaniciId);
        });

        modelBuilder.Entity<SorguCalistirmaLog>(entity =>
        {
            entity.ToTable("audit_QueryExecutionLog", "VIB");
            entity.HasKey(e => e.LogId);
            entity.Property(e => e.SorguId).HasColumnName("QueryId");
            entity.Property(e => e.KatmanKodu).HasColumnName("LayerCode").HasMaxLength(20);
            entity.Property(e => e.CalistirmaZamani).HasColumnName("ExecutedAt");
            entity.Property(e => e.SatirSayisi).HasColumnName("RowCount");
            entity.Property(e => e.SureMs).HasColumnName("DurationMs");
            entity.Property(e => e.Hata).HasColumnName("ErrorMessage");
            entity.Property(e => e.KullaniciId).HasColumnName("UserId");
            entity.HasOne(e => e.Kullanici).WithMany(k => k.SorguCalistirmaLoglari).HasForeignKey(e => e.KullaniciId);
        });
    }
}
