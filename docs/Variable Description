#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))
#set text(font: "Liberation Serif", size: 11pt)

#align(center)[
  #text(weight: "bold", size: 16pt)[Laporan Awal: Struktur Variabel Data Asuransi Kendaraan] \
  #text(size: 12pt, style: "italic")[Persiapan Pemodelan Generalized Linear Model (GLM)]
]

#v(1cm)

== 1. Pendahuluan
Sebelum melakukan pemodelan _Generalized Linear Model_ (GLM), langkah awal yang krusial adalah memastikan validasi struktur dan kesesuaian tipe data[cite: 5]. GLM sangat sensitif terhadap *link function* dan jenis distribusi respons yang digunakan[cite: 5]. Oleh karena itu, variabel harus dikelompokkan dengan benar menjadi variabel kategorikal (faktor) dan variabel kontinu (numerik) agar estimasi parameter model tidak bias.

== 2. Tabel Deskripsi Variabel

Di bawah ini adalah tabel ringkasan variabel yang digunakan dalam data gabungan asuransi kendaraan periode 2011–2018:

#v(0.5cm)

#table(
  columns: (1.5fr, 2fr, 3.5fr),
  inset: 10pt,
  align: (left, left, left),
  fill: (x, y) => if y == 0 { rgb("e0e0e0") } else { none },
  stroke: 0.5pt + rgb("b0b0b0"),
  
  // Header
  [*Nama Variabel*], [*Tipe Data R*], [*Deskripsi & Catatan Validasi*],

  // Kategorikal
  [SEX], [Factor / Category], [Jenis kelamin pemegang polis. Harus dikonversi dari numerik (0/1).],
  [INSR_TYPE], [Factor / Category], [Jenis asuransi kendaraan yang dipilih.],
  [TYPE_VEHICLE], [Factor / Category], [Kategori atau jenis kendaraan.],
  [MAKE], [Factor / Category], [Merek atau pabrikan kendaraan.],
  [USAGE], [Factor / Category], [Tujuan penggunaan kendaraan (misal: pribadi/komersial).],

  // Kontinu
  [INSURED_VALUE], [Continuous / Numeric], [Nilai pertanggungan atau harga kendaraan yang diasuransikan.],
  [PREMIUM], [Continuous / Numeric], [Jumlah premi asuransi yang dibayarkan.],
  [PROD_YEAR], [Continuous / Numeric], [Tahun produksi kendaraan.],
  [SEATS_NUM], [Continuous / Numeric], [Jumlah kapasitas tempat duduk kendaraan.],
  [CARRYING_CAPACITY], [Continuous / Numeric], [Kapasitas muatan kendaraan. Perlu pembersihan khusus karena adanya inkonsistensi string/teks di file tertentu.],
  [CCM_TON], [Continuous / Numeric], [Kapasitas mesin (CC) atau berat tonase kendaraan. Memiliki korelasi linear kuat dengan TYPE_VEHICLE.],
  [CLAIM_PAID], [Continuous / Numeric], [Jumlah klaim yang dibayarkan (Variabel respon/dependen).]
)

#v(0.5cm)

== 3. Catatan Penting untuk Tahap Berikutnya
* *Inkonsistensi Tipe Data:* Kolom `CARRYING_CAPACITY` terdeteksi terbaca sebagai teks (_string_) pada data 2014–2018 akibat adanya entri kosong atau karakter non-numerik (seperti "-" atau "NA")[cite: 25, 26, 27]. Kolom ini wajib dibersihkan dan dipastikan bertipe numerik sebelum digabungkan[cite: 25, 30].
* *Multikolinieritas:* Variabel `CCM_TON` memiliki korelasi linear yang kuat dengan `TYPE_VEHICLE` atau `INSURED_VALUE`[cite: 10]. Pemeriksaan nilai *VIF (Variance Inflation Factor)* atau *Cramer's V* wajib dilakukan karena multikolinieritas dapat membuat standard error model GLM membengkak[cite: 11, 12].
* *Potensi Overlapping:* Perlu dilakukan pemeriksaan _cleansing_ data pada tahun pembatas (2014) untuk memastikan tidak ada data transaksi yang terekspor dua kali agar tidak terjadi _over-counting_ pada bobot risiko model[cite: 35, 51, 52].
