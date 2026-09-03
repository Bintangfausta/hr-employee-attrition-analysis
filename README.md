# HR Employee Attrition & Workforce Diagnostics Analysis

## 1. Executive Summary

Proyek ini menganalisis data karyawan internal perusahaan (employee-level HR records) untuk mendiagnosis pola turnover, komposisi demografis, dan struktur tenaga kerja di seluruh departemen dan lokasi. Analisis ini tidak berhenti pada pelaporan headcount sederhana, melainkan menjawab pertanyaan bisnis inti: **segmen karyawan, departemen, dan pola tenure mana yang paling berisiko terhadap attrition — dan strategi retensi apa yang perlu diprioritaskan oleh HR leadership?**

### Business Goals & Objectives

- Mengukur komposisi gender, ras/etnis, dan usia dari workforce aktif saat ini untuk mendukung pelaporan diversity, equity & inclusion (DEI).
- Mengidentifikasi departemen dengan turnover rate tertinggi agar intervensi retensi dapat diprioritaskan secara tepat sasaran.
- Mengkuantifikasi rata-rata masa kerja (length of employment) karyawan yang telah resign/terminated sebagai benchmark retensi.
- Menghitung rata-rata tenure per departemen untuk membedakan departemen dengan loyalitas karyawan tinggi versus yang rentan churn.
- Melacak tren headcount tahunan (hires vs. terminations) untuk mendeteksi periode penyusutan atau pertumbuhan struktural pada organisasi.
- Memetakan distribusi karyawan berdasarkan job title, lokasi (headquarters vs. remote), dan state untuk mendukung perencanaan tenaga kerja (workforce planning).
- Menerjemahkan raw employee records yang belum bersih menjadi dataset analysis-ready melalui pipeline data cleaning yang terdokumentasi.

---

## 2. Tech Stack / Tools Used

| Layer | Tools |
|---|---|
| Database | MySQL |
| Data Cleaning & Preparation | SQL (`ALTER TABLE`, `UPDATE`, `STR_TO_DATE`, `TIMESTAMPDIFF`) |
| Analysis & Querying | SQL (Aggregations, `CASE WHEN`, Subqueries, `GROUP BY`) |
| Visualization / Dashboard | Microsoft Power BI Desktop |
| Data Source | `human_resources.csv` |

---

## 3. Business Problems Addressed

Analisis ini disusun berdasarkan 11 pertanyaan bisnis inti berikut. Kecuali dinyatakan lain, scope analisis dibatasi pada karyawan dengan usia legal kerja (`age >= 18`); sebagian besar pertanyaan lebih lanjut dibatasi pada karyawan yang saat ini masih aktif (`termdate IS NULL`).

1. Bagaimana komposisi gender dari karyawan aktif saat ini?
2. Bagaimana komposisi ras/etnis dari karyawan aktif saat ini?
3. Bagaimana distribusi usia karyawan aktif — secara keseluruhan, per age group, dan per age group × gender?
4. Berapa proporsi karyawan yang bekerja di headquarters dibandingkan lokasi remote?
5. Berapa rata-rata masa kerja (length of employment) untuk karyawan yang sudah resign/terminated?
6. Bagaimana distribusi gender bervariasi antar departemen?
7. Bagaimana distribusi job title di seluruh perusahaan?
8. Departemen mana yang memiliki turnover rate tertinggi?
9. Bagaimana sebaran karyawan berdasarkan state?
10. Bagaimana tren headcount berubah dari waktu ke waktu (hires vs. terminations per tahun, net change)?
11. Berapa rata-rata tenure karyawan di masing-masing departemen?

---

## 4. Data Pipeline & Methodology

Proyek ini mengikuti alur kerja **Data Cleaning → Exploratory Data Analysis**, keduanya dieksekusi langsung di MySQL.

**Stage 1 — Data Cleaning & Preparation (`hr_data_cleaning.sql`)**
- Mengimpor dataset mentah `Human_Resources.csv` ke tabel `hr` pada database `projects`.
- Memperbaiki artifact encoding BOM (Byte Order Mark) pada nama kolom pertama hasil import, mengganti nama kolom menjadi `emp_id` yang human-readable.
- Menstandarkan dua kolom tanggal (`birthdate`, `hire_date`) yang tersimpan dalam format campuran (`MM/DD/YYYY` dan `MM-DD-YYYY`) menjadi format ISO (`YYYY-MM-DD`) menggunakan logika `CASE WHEN` + `STR_TO_DATE`, kemudian mengubah tipe kolom menjadi `DATE` asli.
- Membersihkan kolom `termdate` melalui dua langkah: mengonversi string kosong (karyawan yang masih aktif) menjadi `NULL` sejati, lalu mem-parsing timestamp UTC yang tersisa (mis. `2011-05-14 00:00:00 UTC`) menjadi tipe `DATE` murni.
- Menurunkan kolom `age` baru menggunakan `TIMESTAMPDIFF(YEAR, birthdate, CURDATE())` untuk mendukung segmentasi usia di tahap analisis.
- Menjalankan serangkaian data quality check: memvalidasi rentang usia hasil konversi, menandai record dengan usia di bawah batas usia kerja legal (<18 tahun) untuk dikecualikan dari analisis, memastikan tidak ada `termdate` yang jatuh di masa depan, dan menghitung jumlah karyawan aktif (`termdate IS NULL`).

**Stage 2 — Exploratory Data Analysis & Business Querying (`hr_exploratory_data_analysis.sql`)**
- Menjalankan 11 query bisnis pada tabel `hr` yang sudah bersih, dengan scope konsisten (`age >= 18`, sebagian besar juga `termdate IS NULL`).
- Menerapkan agregasi `GROUP BY` untuk merangkum breakdown gender, ras/etnis, lokasi, job title, dan state.
- Menggunakan logika `CASE WHEN` untuk melakukan binning usia ke dalam age group (18-24 hingga 65+).
- Menghitung turnover rate per departemen dengan membandingkan jumlah karyawan terminated terhadap total karyawan yang pernah tercatat di departemen tersebut (aktif + terminated).
- Membangun subquery untuk menghitung tren headcount tahunan — hires, terminations, net change, dan net change percentage — per tahun hire.
- Menghitung average tenure per departemen dengan logika kondisional: karyawan yang sudah keluar dihitung dari `hire_date` → `termdate`, sedangkan karyawan yang masih aktif dihitung dari `hire_date` → tanggal saat ini (`CURDATE()`).

---

## 5. Key Workforce Insights & HR Recommendations

Insight berikut disintesis dari hasil eksekusi 11 query bisnis dan dashboard Power BI, masing-masing dipasangkan dengan rekomendasi konkret untuk HR leadership.

**Catatan skop data:** angka gender, ras/etnis, dan usia (Insight 4–5) merepresentasikan **karyawan aktif saat ini** (17.482 orang, hasil filter `age >= 18 AND termdate IS NULL`). Sementara itu, angka lokasi, distribusi gender per departemen, dan job title (Insight 1, 3, 6) merepresentasikan **seluruh karyawan yang pernah tercatat** — aktif maupun sudah resign — pada usia kerja legal (21.247 orang). Kedua angka ini berasal dari scope filter yang berbeda pada query aslinya; disebutkan secara eksplisit di sini agar tidak disalahartikan sebagai inkonsistensi data saat kedua kelompok insight dibaca berdampingan.

**Insight 1 — Karyawan yang Resign Keluar Jauh Lebih Cepat daripada Rata-Rata Tenure Departemen**
- Rata-rata *length of employment* untuk karyawan yang sudah *terminated* hanya **8 tahun**, sementara rata-rata tenure per departemen (gabungan aktif + resign) berkisar **13,9–14,9 tahun** — gap sekitar 6–7 tahun.
- Ini mengindikasikan angka tenure keseluruhan banyak "ditopang" oleh karyawan lama yang bertahan sangat panjang, sementara karyawan yang memilih keluar melakukannya jauh sebelum mencapai rata-rata masa kerja perusahaan.
- **Rekomendasi:** fokuskan exit-interview analysis dan program retensi pada window tahun ke-5 hingga ke-8 masa kerja — titik yang tampak paling rawan terhadap voluntary attrition berdasarkan gap ini.

**Insight 2 — Auditing dan Legal Mencatat Turnover Rate Tertinggi, Meski Headcount-nya Kecil**
- **Auditing** mencatat turnover rate tertinggi perusahaan (**20,0%**, dari total 50 karyawan), diikuti **Legal** (**17,1%**, dari 299 karyawan) dan **Training** (14,0%, dari 1.622 karyawan).
- Sebagai pembanding, departemen dengan headcount terbesar seperti **Engineering** (6.387 karyawan) dan **Accounting** (3.192 karyawan) justru mencatat turnover rate lebih rendah — masing-masing 13,1% dan 12,9%. Departemen dengan turnover terendah adalah **Marketing** (11,0%) dan **Business Development** (11,6%).
- **Rekomendasi:** meskipun headcount Auditing & Legal kecil secara absolut, turnover setinggi ini pada fungsi compliance/governance berisiko pada institutional knowledge loss dan risk exposure perusahaan. Prioritaskan retention program dan succession planning di kedua departemen ini, bukan hanya di departemen dengan headcount terbesar.

**Insight 3 — Mayoritas Workforce di Usia Produktif, Representasi Non-Conforming Tidak Merata Antar Departemen**
- Komposisi gender karyawan aktif: **Male 8.911 (51,0%)**, **Female 8.090 (46,3%)**, **Non-Conforming 481 (2,8%)**.
- Usia karyawan aktif terkonsentrasi pada rentang produktif 25–44 tahun (57,3% dari total: 25–34 = 28,2%, 35–44 = 29,2%); hanya 2,9% berada di entry-level 18–24 tahun, dan 12,1% mendekati usia pensiun (55–64 tahun) — tidak ada segmen 65+ yang tercatat.
- Representasi Non-Conforming per departemen bervariasi lebar: dari **0%** di Auditing (0 dari 50) dan **1,0%** di Marketing (5 dari 480), hingga **>3%** di Support (3,8%) dan Research and Development (3,4%).
- **Rekomendasi:** struktur usia yang terkonsentrasi di usia produktif adalah aset, namun porsi entry-level yang sangat tipis (2,9%) berisiko pada talent pipeline jangka panjang — evaluasi strategi entry-level hiring/internship. Variasi representasi Non-Conforming antar departemen juga layak menjadi fokus audit inclusive hiring per fungsi, bukan hanya di level perusahaan.

**Insight 4 — Diversitas Ras/Etnis Cukup Tersebar, Tanpa Kelompok yang Mendominasi Ekstrem**
- Dari 17.482 karyawan aktif: **White** 4.987 (28,5%), **Two or More Races** 2.867 (16,4%), **Black or African American** 2.840 (16,2%), dan **Asian** 2.791 (16,0%) — tiga kelompok terakhir ini jaraknya sangat tipis satu sama lain.
- **Hispanic or Latino** 1.994 (11,4%), **American Indian or Alaska Native** 1.051 (6,0%), dan **Native Hawaiian or Other Pacific Islander** 952 (5,4%) melengkapi komposisi dengan porsi lebih kecil namun tetap signifikan.
- **Rekomendasi:** tidak ada kelompok yang mendominasi secara ekstrem (grup terbesar hanya 28,5% dari total) — sinyal positif untuk diversity reporting di level headcount. Validasi lebih lanjut representasi ras/etnis di level job title senior/leadership (bukan hanya total headcount) untuk memastikan diversity juga tercermin di jenjang karir yang lebih tinggi.

**Insight 5 — Efektivitas Retensi Membaik Konsisten Selama Dua Dekade (2000–2020)**
- Net change headcount positif di setiap tahun, dengan *net change percent* naik dari titik terendah **80,6% (2006)** menjadi titik tertinggi **94,7% (2020)**.
- Jumlah terminations tahunan turun tajam dari puncaknya **207 (2006)** menjadi hanya **51 (2020)** — turun ~75% — meski volume hiring relatif stabil di kisaran 1.000–1.100 per tahun pada periode yang sama.
- **Rekomendasi:** tren perbaikan retensi pasca-2006 ini bernilai sebagai institutional knowledge — identifikasi kebijakan atau perubahan operasional apa yang mendasarinya, lalu jadikan playbook tersebut acuan untuk menekan turnover di departemen yang masih tertinggal seperti Auditing dan Legal (Insight 3).

---

## 6. Repository Structure

```
hr-employee-attrition-analysis/
│
├── README.md                              # Project overview and business insights
├──  human_resources.csv                   # Raw source dataset
│
├── hr_data_cleaning.sql                   # Data cleaning & preparation (MySQL)
├── hr_exploratory_data_analysis.sql       # EDA & 11 business problem queries (MySQL)
│
├── outputs/
│   ├── query_results.docx                 # Hasil mentah seluruh 11 query (tabel & screenshot)
│   └── jobtitle_question7.csv             # Detail hasil Q7: distribusi 185 job title
│
└── dashboard_employee_distribution_report.pdf   # Dashboard Power BI (ringkasan visual)
└── dashboard_employee_distribution_report.pdf   # Dashboard Power BI (ringkasan visual)
```

---

### Author's Note
Proyek ini mendemonstrasikan end-to-end HR analytics workflow — mulai dari raw employee records yang belum bersih (encoding artifact, format tanggal campuran, missing termination dates) hingga menjadi dataset relasional yang bersih, dilanjutkan dengan business intelligence berbasis SQL — mencerminkan jenis analisis yang akan disampaikan seorang People/HR data analyst untuk mendukung pengambilan keputusan retensi dan workforce planning di level leadership.
