# 📊 BrightTV Viewership Analytics

![SQL](https://img.shields.io/badge/SQL-Databricks-orange)
![Excel](https://img.shields.io/badge/Tool-Excel-green)
![Status](https://img.shields.io/badge/Project-Completed-brightgreen)
![License](https://img.shields.io/badge/License-Academic-blue)
![Made by](https://img.shields.io/badge/Author-Lungile%20Chirwa-purple)

---

## 📌 Project Overview

This project analyzes **BrightTV user profiles and viewership data** to generate actionable insights that support the **Customer Value Management (CVM)** team in growing the subscription base.

The analysis focuses on identifying **user behavior patterns, content consumption trends, and opportunities to improve engagement**, particularly during low-activity periods.

---

## 🎯 Objectives

* Analyze user demographics and viewing behavior
* Identify key drivers of content consumption
* Detect peak and low engagement periods
* Recommend strategies to increase user engagement and subscriptions

---

## 🗂️ Dataset Description

### 1. User Profiles

Contains demographic information such as:

* UserID
* Age
* Gender
* Province
* Race

### 2. Viewership Data

Contains viewing session data:

* UserID
* Channel
* Timestamp (UTC)
* Duration

---

## ⚙️ Tools & Technologies

* **Databricks SQL** – Data transformation and analysis
* **Microsoft Excel** – Pivot tables and visualization
* **PowerPoint** – Presentation of insights

---

## 🔧 Data Processing Steps

### 1. Data Cleaning

* Converted timestamps from **UTC to South African Time (SAST)**
* Handled missing/null values using `COALESCE` and `CASE WHEN`

### 2. Feature Engineering

* Extracted:

  * Watch date
  * Watch hour
  * Day of week

### 3. Data Aggregation

* Total sessions per user
* Total watch time
* Unique channels watched

### 4. Data Integration

* Joined **user profiles** with **viewership data** using `UserID`

---

## 📊 Key Insights

### ⏰ Peak Viewing Times

* Highest engagement occurs during **evening hours (18:00–21:00)**

### 📅 Low Consumption Periods

* Certain weekdays show **below-average engagement**

### 👥 Demographic Trends

* Users aged **25–44** are the most active
* Urban provinces show higher engagement levels

### 📺 Content Performance

* A small number of channels drive the majority of viewership

---

## 💡 Recommendations

### 📌 Content Strategy

* Promote high-performing channels
* Invest in popular content categories

### 📌 Engagement Strategy

* Release content during peak hours
* Introduce promotions on low-consumption days

### 📌 Growth Strategy

* Target high-engagement demographics
* Expand marketing in underperforming regions

---

## 📈 Visualizations

Visual insights were created using **Excel Pivot Tables**, including:

* Viewership by hour
* Viewership by day
* Top channels
* Demographic breakdowns

---

## 📽️ Presentation

A PowerPoint presentation was created to communicate findings and recommendations effectively.

---

## 🚀 Future Improvements

* Implement machine learning for content recommendations
* Build real-time dashboards using Power BI or Tableau
* Incorporate additional user behavior data

---

## 👤 Author

**Lungile Chirwa**

---

## 📎 Notes

* All timestamps were converted to **SAST (UTC+2)**
* Null values were handled to ensure accurate analysis

---

