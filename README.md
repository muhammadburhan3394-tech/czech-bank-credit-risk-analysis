# Credit Risk & Macroeconomic Impact Analysis (Czech Bank)

**Live Interactive Dashboard:**[https://public.tableau.com/app/profile/muhammad.burhanudin7978/viz/CreditRiskMacroeconomicAnalysis-CzechBankDataset/ExecutiveCreditRiskDashboard]

## 🎯 Business Problem
The bank experienced a significant spike in its Non-Performing Loan (NPL) ratio during the second half of 1993. This analysis aims to investigate whether this surge in credit risk was driven by internal operational factors or influenced by external macroeconomic pressures, specifically the national unemployment rate.

## 📊 Data & Methodology
This project demonstrates an end-to-end data analytics pipeline utilizing the PKDD'99 financial dataset:
1. **Data Extraction (SQL):** Queried and aggregated customer, loan, and transaction tables from a MySQL database to calculate monthly outstanding balances and NPL ratios.
2. **Data Wrangling (Python/Pandas):** Cleaned the dataset, standardized datetime formats, and merged internal banking metrics with external macroeconomic datasets.
3. **Data Visualization (Tableau):** Designed an interactive executive summary dashboard to present findings to business stakeholders.

## 💡 Key Insights
![Dashboard Preview](insert_your_screenshot_filename_here.png)
*(Note: Replace the text in the bracket above with your actual image filename)*

Based on the statistical and visual analysis:
* There is a **moderate positive correlation (0.59)** between the macroeconomic unemployment rate and the deterioration of the bank's credit quality.
* The NPL ratio peaked at 30.97% in December 1993, which directly coincided with the unemployment rate rising to 6.8%.

## 🚀 Recommendations
1. **Tighten Underwriting Policies:** The credit risk team should restrict loan approval criteria and increase collateral requirements when macroeconomic indicators begin to show negative trends.
2. **Develop an Early Warning System:** Integrate national unemployment and layoff trends as leading indicators to proactively mitigate default risks before the NPL ratio worsens.

## 📁 Repository Files
* `1_data_extraction.sql`: MySQL script used for extracting and aggregating credit metrics.
* `Rasio_NPL_Bank_Czech.ipynb`: Jupyter Notebook detailing the data wrangling process and correlation testing.
* `npl_makro_gabungan.csv`: The final processed dataset used for visualization.
