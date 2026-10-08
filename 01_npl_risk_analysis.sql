/* ============================================================================
PROYEK: Analisis Risiko Kredit Macet (NPL) - Portfolio 1
AUTHOR: Muhammad Burhanudin
TANGGAL: 04 Oktober 2026
DESKRIPSI: 
Skrip ini menganalisis tren pertumbuhan NPL bulanan dan menghitung 
rasio NPL terhadap total penyaluran kredit menggunakan fungsi CTE dan Window Function.
============================================================================ */



CREATE DATABASE czech_bank_db;
USE czech_bank_db;

-- kita hanya akan fokus membuat 3 table saja yaitu district, account, dan loan

-- 1.Table wilayah (district)
CREATE table district (
	district_id INT PRIMARY KEY,
    district_name VARCHAR(50),
    region VARCHAR(50),
    no_of_inhabitants INT,
    no_of_municipalities_lt_499 INT,
    no_of_municipalities_500_1999 INT,
    no_of_municipalities_2000_9999 INT,
    no_of_municipalities_gt_10000 INT,
    no_of_cities INT,
    ratio_of_urban_inhabitants FLOAT,
    average_salary INT,
    unemployment_rate_95 FLOAT,
    unemployment_rate_96 FLOAT,
    no_of_enterpreneurs INT,
    no_of_committed_crimes_95 INT,
    no_of_committed_crimes_96 INT
);

-- 2. Table rekening (account)
CREATE table account (
	account_id INT PRIMARY KEY,
    district_id INT,
    statement_frequency VARCHAR (50),
    opened_date int,
    foreign key (district_id) references district(district_id)
);
    
-- 3. Table pinjaman (loan)
CREATE table loan (
	loan_id INT PRIMARY KEY,
    account_id INT,
    loan_date INT,
    loan_amount INT,
    loan_duration INT,
    payment_amount FLOAT,
    loan_status VARCHAR (10),
    foreign key (account_id) references account(account_id)
);

-- Import data ke table yang sudah dibuat
-- jika data yang akan di import cukup besar, maka gunakan secure server

SHOW VARIABLES LIKE "secure_file_priv";

-- setelah di co-pas manual, maka lakukan query import 

-- 1. Import Wilayah
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/district.csv'
INTO TABLE district
FIELDS TERMINATED BY ";" ENCLOSED BY '"'
LINES TERMINATED BY "\r\n"
IGNORE 1 LINES
(	district_id,                
    district_name,
    region,
    no_of_inhabitants,
    no_of_municipalities_lt_499,
    no_of_municipalities_500_1999,
    no_of_municipalities_2000_9999,
    no_of_municipalities_gt_10000,
    no_of_cities,
    ratio_of_urban_inhabitants,
    average_salary,
    @unemployment_rate_95,            -- ditampung dulu di variabel @
    unemployment_rate_96,
    no_of_enterpreneurs,
    @no_of_committed_crimes_95,       -- ditampung dulu di variabel @
    no_of_committed_crimes_96 
) 
SET
unemployment_rate_95 = NULLIF(@unemployment_rate_95,'?'),
no_of_committed_crimes_95 = NULLIF(@no_of_committed_crimes_95,'?');

-- 2. Import Rekening (Account)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/account.csv'
INTO TABLE account
FIELDS TERMINATED BY ";" ENCLOSED BY '"'
LINES TERMINATED BY "\r\n"
IGNORE 1 LINES;	

-- 3. Import Pinjaman (Loan)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/loan.csv'
INTO TABLE loan
FIELDS TERMINATED BY ";" ENCLOSED BY '"'
LINES TERMINATED BY "\r\n"
IGNORE 1 LINES
(loan_id, account_id, loan_date, loan_amount, loan_duration, payment_amount, loan_status);

-- Mengkategorikan kredit berdasarkan status nya
SELECT loan_status,                         
	COUNT(loan_id) as total_loans,
	SUM(loan_amount) as total_amount
FROM loan
GROUP BY loan_status
ORDER BY total_amount DESC;

SELECT CASE 
	WHEN loan_status = 'A' THEN 'Lancar (Selesai/Lunas)'
    WHEN loan_status = 'B' THEN 'Macet (Selesai/Gagal Bayar)'
    WHEN loan_status = 'C' THEN 'Lancar (Sedang Berjalan)'
    WHEN loan_status = 'D' THEN 'Macet (Sedang Menunggak)'
    ELSE 'Lainnya'
END AS deskripsi_status,
	COUNT(loan_id) as total_loans,
	SUM(loan_amount) as total_amount
FROM loan
GROUP BY loan_status
ORDER BY total_amount DESC;


-- kalau mau digabungkan hanya menjadi 2 kategory saja
SELECT CASE                                     
	WHEN loan_status IN ('A','C') THEN 'Kredit Lancar'
    WHEN loan_status IN ('B','D') THEN 'Kredit Macet / NPL'
    ELSE 'Lainnya'
END AS kategori_kredit,
	COUNT(loan_id) as total_loans,
	SUM(loan_amount) as total_amount
FROM loan
GROUP BY kategori_kredit
ORDER BY total_amount DESC;

# TAHAP 1 / TAHAP PROFILING ---->  EDA (MENGHITUNG NPL)
-- kalau mau menghitung NPL dengan nested query
SELECT                                      
	SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
	SUM(loan_amount) AS total_portfolio_amount,
    ROUND(
		SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END)/SUM(loan_amount)*100,2
        ) AS npl_ratio_percentage
FROM loan;

-- cara Opsi kedua --> menghitung NPL dengan teknik CTE (dengan WITH)
WITH summary_kredit AS (
	SELECT
    SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
	SUM(loan_amount) AS total_portfolio_amount
    FROM loan
    )
SELECT 
	total_npl_amount,
    total_portfolio_amount,
    ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage
FROM summary_kredit;

# TAHAP 2 / TAHAP DIAGNOSA ---->  Dimana Sumber Masalahnya
-- Challenge Menemukan 5 Wilayah dengan kredit macet NPL terbesar
-- Join dataset menggunakan account sebagai foreign key --> account dengan district (district_id) dan account dengan loan (account_id)

SELECT d.district_name,
	   d.region,
       SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
	   COUNT(l.loan_id) AS total_deb
FROM loan as l
JOIN account as a ON l.account_id = a.account_id
JOIN district as d ON a.district_id = d.district_id
GROUP BY d.district_name, d.region
ORDER BY total_npl_amount DESC
LIMIT 5;

-- Challenge Selanjutnya Menemukan 5 Wilayah dengan RASIO kredit macet NPL terbesar (Agar lebih Fair dihitung dari ratio nya)
-- Menggunakan teknik CTE (with clause)

WITH district_kredit as (
	SELECT d.district_name,
	       d.region,
			SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
            SUM(loan_amount) AS total_portfolio_amount,
			COUNT(l.loan_id) AS total_deb
	FROM loan as l
	JOIN account as a ON l.account_id = a.account_id
	JOIN district as d ON a.district_id = d.district_id
	GROUP BY d.district_name, d.region
)
SELECT
	district_name,
    region,
    total_npl_amount,
    total_portfolio_amount,
    ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage
FROM district_kredit
WHERE total_portfolio_amount > 0
ORDER BY npl_ratio_percentage DESC
LIMIT 5;



# TAHAP 3 / TAHAP DIAGNOSA AKAR MASALAH ---->  Mengapa hal itu terjadi
-- Challenge Menemukan PENYEBAB 5 Wilayah dengan kredit macet NPL terbesar
-- Apakah ada korelasi antara NPL dengan indicator makro ekonomi yang lain
-- Kita gabungkan data Kinerja Kredit dengan average_salary & unemployment_rate_96 (di dataset district)

WITH district_kredit as (
	SELECT 
		   d.district_name,
	       d.region,
           d.average_salary,
           d.unemployment_rate_96,
		   SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
		   SUM(loan_amount) AS total_portfolio_amount,
		   COUNT(l.loan_id) AS total_deb
	FROM loan as l
	JOIN account as a ON l.account_id = a.account_id
	JOIN district as d ON a.district_id = d.district_id
	GROUP BY d.district_name, d.region, d.average_salary, d.unemployment_rate_96
)
SELECT
	district_name,
    region,
    average_salary,
    unemployment_rate_96,
    total_npl_amount,
    total_portfolio_amount,
    ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage
FROM district_kredit
WHERE total_portfolio_amount > 0
ORDER BY npl_ratio_percentage DESC
LIMIT 5;


-- ## Dibuat ranking (dense_rank) agar semakin jelas visual nya --------> WINDOWS FUNCTION PERINGKAT
WITH district_kredit as (
	SELECT 
		   d.district_name,
	       d.region,
           SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
		   SUM(loan_amount) AS total_portfolio_amount
	FROM loan as l
	JOIN account as a ON l.account_id = a.account_id
	JOIN district as d ON a.district_id = d.district_id
	GROUP BY d.district_name, d.region
)
SELECT
	district_name,
    region,
    ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage,
    DENSE_RANK () OVER (ORDER BY (total_npl_amount/total_portfolio_amount) DESC) AS peringkat_resiko            #=========> FUNGSI RANKING 
FROM district_kredit
WHERE total_portfolio_amount > 0
LIMIT 5;


-- ## Dibuat ranking (dense_rank) dalam KUMPULAN agar semakin jelas visual nya --------> WINDOWS FUNCTION PARTITION BY
-- ## Agar semakin jelas ranking dalam setiap masing-masing region (LAPORAN KERJA REGIONAL BUKAN NASIONAL)

WITH district_kredit as (
	SELECT 
		   d.district_name,
	       d.region,
           SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
		   SUM(loan_amount) AS total_portfolio_amount
	FROM loan as l
	JOIN account as a ON l.account_id = a.account_id
	JOIN district as d ON a.district_id = d.district_id
	GROUP BY d.district_name, d.region
)
SELECT
	district_name,
    region,
    ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage,
    DENSE_RANK () OVER (                                                #=========> FUNGSI RANKING  
    PARTITION BY region                                                 #=========> FUNGSI KUMPULAN
    ORDER BY (total_npl_amount/total_portfolio_amount) DESC
    ) AS ranking_dalam_region                                            
FROM district_kredit
WHERE total_portfolio_amount > 0
ORDER BY region, ranking_dalam_region;



-- ## Memfilter Data hanya menampilkan peringkat 1 dari masing-masing Region dengan WINDOWS FUNTION CHAINED CTE
-- ## ====-> Ada 2 CTE di jadikan dalam 1 Kuery dengan menggunakan tanda ( , )

WITH district_kredit as (
	SELECT 
		   d.district_name,
	       d.region,
           SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS total_npl_amount,
		   SUM(loan_amount) AS total_portfolio_amount
	FROM loan as l
	JOIN account as a ON l.account_id = a.account_id
	JOIN district as d ON a.district_id = d.district_id
	GROUP BY d.district_name, d.region
),
	ranking_district AS (
	SELECT
		district_name,
		region,
		ROUND((total_npl_amount/total_portfolio_amount)*100,2) AS npl_ratio_percentage,
		DENSE_RANK () OVER (                                                #=========> FUNGSI RANKING  
		PARTITION BY region                                                 #=========> FUNGSI KUMPULAN
		ORDER BY (total_npl_amount/total_portfolio_amount) DESC
		) AS ranking_dalam_region                                            
	FROM district_kredit
	WHERE total_portfolio_amount > 0
	ORDER BY region, ranking_dalam_region
)
SELECT 
	district_name,
    region,
    npl_ratio_percentage,
    ranking_dalam_region
FROM ranking_district
WHERE ranking_dalam_region = 1
ORDER BY region;


-- ## Analisis Tren Waktu (Time-Series Analysis) menggunakan fungsi LAG ()
ALTER table loan                    # Menambah kolom baru untuk memperbaiki type dari loan_date dari int ke date
ADD column loan_date_clean DATE after loan_date;

UPDATE loan
SET loan_date_clean = str_to_date(CAST(loan_date as CHAR), '%y%m%d');

ALTER table loan                     # Menghapus kolom lama loan_date
DROP column loan_date;

ALTER table loan
RENAME column loan_date_clean to loan_date;


-- ## Analisis Tren Waktu (Time-Series Analysis) menggunakan fungsi LAG ()

WITH bulanan_kredit AS (                       # BLOK 1 --> CTE --> Tugasnya meringkas ribuan transaksi harian menjadi total penyaluran kredit per bulan
	SELECT
		EXTRACT(YEAR_MONTH FROM loan_date) AS periode,
        SUM(loan_amount) AS total_penyaluran
	FROM loan
    GROUP BY EXTRACT(YEAR_MONTH FROM loan_date)
)
SELECT                 # BLOK 2 --> KUERY UTAMA
	periode,
    total_penyaluran AS penyaluran_bulan_ini,
    LAG(total_penyaluran,1)OVER(ORDER BY periode) AS penyaluran_bulan_lalu,     #"Tolong ambilkan nilai total_penyaluran dari 1 baris tepat di atas saya, diurutkan berdasarkan bulan."
    ROUND(                                                                     
		(total_penyaluran - LAG(total_penyaluran,1)OVER(ORDER BY periode)) / LAG(total_penyaluran,1)OVER(ORDER BY periode) *100,2         # Murni rumus persentase perubahan (percentage change) yang biasa dipakai di Excel.
        ) AS pertumbuhan_mom
FROM bulanan_kredit;




-- ## Jika ingin mengetahui angka pertumbuhan NPL nya saja maka tinggal diganti pertumbuhan total penyaluran dengan pertumbuhan kredit macet saja 
-- ## Ganti SUM(loan_amount) di dalam CTE menjadi SUM(CASE WHEN loan_status IN ('B', 'D') THEN loan_amount ELSE 0 END))

WITH bulanan_npl AS (                       
	SELECT
		EXTRACT(YEAR_MONTH FROM loan_date) AS periode,
        SUM(CASE WHEN loan_status IN ('B', 'D') THEN loan_amount ELSE 0 END) AS npl_baru_bulan_ini
	FROM loan
    GROUP BY EXTRACT(YEAR_MONTH FROM loan_date)
),
akumulasi_npl AS (
	SELECT                 
		periode,
		npl_baru_bulan_ini,
		SUM(npl_baru_bulan_ini)OVER(ORDER BY periode) AS total_akumulasi_npl      #--> Menghitung Akumulasi NPL dari awal hingga bulan berjalan
   FROM bulanan_npl
)
SELECT
	periode,
    npl_baru_bulan_ini,
    total_akumulasi_npl AS npl_outstanding_saat_ini,
    LAG(total_akumulasi_npl,1) OVER (ORDER BY periode) AS npl_outstanding_bulan_lalu,
ROUND(
	(total_akumulasi_npl - LAG(total_akumulasi_npl,1) OVER (ORDER BY periode))
    / NULLIF(LAG(total_akumulasi_npl,1) OVER (ORDER BY periode),0)*100,2           # ---> memakai NULLIF untuk mencegah eror division by zero
	) AS pertumbuhan_npl_mom
FROM akumulasi_npl;
    
-- ## Menghitung Rasio NPL tiap Bulannya (FINAL ANALYTICS) ##--
  
WITH bulanan_gabungan_npl AS (
	SELECT
		EXTRACT(YEAR_MONTH from loan_date) AS periode,
        SUM(loan_amount) AS penyaluran_baru,                                              #--> Total penyaluran kredit baru bulan ini
        SUM(CASE WHEN loan_status IN ('B','D') THEN loan_amount ELSE 0 END) AS npl_baru   #--> Total kredit macet baru bulan ini (status B & D)
	FROM loan
    GROUP BY EXTRACT(YEAR_MONTH from loan_date)
),
akumulasi_portfolio AS (
	SELECT
		periode,
        penyaluran_baru,
        npl_baru,
        SUM(penyaluran_baru) OVER (ORDER BY periode) AS total_penyaluran_outstanding,     #--> Running total penyaluran kredit
        SUM(npl_baru) OVER (ORDER BY periode) AS npl_outstanding						  #--> Running total kredit macet (NPL)
	FROM bulanan_gabungan_npl
)
SELECT
	periode,
    npl_outstanding,
    total_penyaluran_outstanding,
    ROUND(                                                                               #--> Rumus Rasio NPL ( % )
    (npl_outstanding / NULLIF(total_penyaluran_outstanding,0))*100,2
    ) AS npl_ratio
FROM akumulasi_portfolio;
        
  
  
  
  
  
  
  
  
  
 