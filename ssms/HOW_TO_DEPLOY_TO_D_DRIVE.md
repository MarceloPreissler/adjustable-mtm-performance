# How to Deploy MTM Performance Scripts to Your D: Drive

## ✅ **Recommended: Use Git (Easiest)**

Since this is a git repository, the easiest way to get scripts to your D: drive is:

### **Step 1: Clone/Pull the Repository to D: Drive**

```bash
# If you haven't cloned yet
cd D:\
git clone https://github.com/MarceloPreissler/adjustable-mtm-performance.git

# If already cloned, just pull latest
cd D:\adjustable-mtm-performance
git pull origin claude/explore-repository-011CULV68yu9j5R2oZC2aRyV
```

### **Step 2: Open Scripts in SSMS**

All scripts will be in:
```
D:\adjustable-mtm-performance\ssms\
```

You can open them directly in SSMS:
```
File → Open → File → D:\adjustable-mtm-performance\ssms\00_quick_test.sql
```

---

## 🎯 **Alternative: Download Zip Package**

If you don't want to use git, download the zip file:

### **From GitHub:**

1. Go to: https://github.com/MarceloPreissler/adjustable-mtm-performance
2. Click on branch: `claude/explore-repository-011CULV68yu9j5R2oZC2aRyV`
3. Click "Code" → "Download ZIP"
4. Extract to `D:\MTM_Performance\`

### **From Repository:**

If you already have this repository somewhere, you can find:
```
MTM_Performance_SSMS_Scripts.zip
```

Extract it to:
```
D:\MTM_Performance\
```

---

## 📂 **Recommended D: Drive Structure**

```
D:\MTM_Performance\
├── ssms\
│   ├── 00_quick_test.sql                    ← Run this first!
│   ├── discover_tables.sql                  ← Find your tables
│   ├── 01_setup\
│   │   ├── test_linked_servers.sql
│   │   └── create_database_and_tables.sql
│   ├── 02_extraction\
│   │   ├── sp_Extract_MTM_Counts.sql
│   │   ├── sp_Extract_Pricing_Data.sql
│   │   ├── sp_Extract_COGS_and_Plan_Data.sql
│   │   └── sp_Extract_Usage_Data.sql
│   ├── 03_transformation\
│   ├── 04_calculations\
│   ├── 05_analysis\
│   └── master_orchestration.sql
└── README.md
```

---

## 🚀 **Quick Start from D: Drive**

Once files are on D: drive, open SSMS and run:

```sql
-- Step 1: Quick test (verify linked servers work)
:r "D:\MTM_Performance\ssms\00_quick_test.sql"

-- Step 2: Discover tables (find your data)
:r "D:\MTM_Performance\ssms\discover_tables.sql"

-- Step 3: Create database
:r "D:\MTM_Performance\ssms\01_setup\create_database_and_tables.sql"

-- Step 4: Create extraction procedures
:r "D:\MTM_Performance\ssms\02_extraction\sp_Extract_MTM_Counts.sql"

-- Continue with remaining setup...
```

---

## 💡 **Why Git is Better:**

✅ Easy updates - just `git pull` to get latest changes
✅ Version history - see all changes over time
✅ Automatic sync - changes I make appear instantly
✅ No manual copying - everything stays in sync

---

## 📞 **Need Help?**

If you have issues accessing your D: drive or setting this up, let me know and I'll provide step-by-step instructions!
