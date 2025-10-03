# Documentation Index

## Overview
This directory contains comprehensive documentation for the Shop1 CMMS system, focusing on database schemas, authentication, and system conformance.

---

## 📚 Documentation Files

### 🚀 Start Here (New Developers)
1. **[DEVELOPER_SCHEMA_GUIDE.md](./DEVELOPER_SCHEMA_GUIDE.md)** - Onboarding guide with common mistakes and quick tips
2. **[SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md)** - Quick field lookup for all schemas

### 📖 Reference Documentation
3. **[DATABASE_TABLE_MAP.md](./DATABASE_TABLE_MAP.md)** - Complete table and schema mapping
4. **[AUTH_STATUS_REPORT.md](./AUTH_STATUS_REPORT.md)** - Authentication system conformance analysis

### 🔍 Audit Reports
5. **[SCHEMA_CONFORMANCE_AUDIT.md](./SCHEMA_CONFORMANCE_AUDIT.md)** - Detailed schema validation findings
6. **[SYSTEMATIC_AUDIT_SUMMARY.md](./SYSTEMATIC_AUDIT_SUMMARY.md)** - Complete audit results and fixes

---

## 🎯 Quick Links by Task

### "I need to add a new field to a schema"
→ Read: [SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md) - Section: "Adding New Fields"

### "I'm getting KeyError on a field"
→ Check: [SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md) - Section: "Common Mistakes to Avoid"

### "What fields exist on pm_schedules?"
→ Lookup: [SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md) - Section: "pm_schedules Table"

### "How does authentication work?"
→ Read: [AUTH_STATUS_REPORT.md](./AUTH_STATUS_REPORT.md)

### "What's the relationship between tables?"
→ See: [DATABASE_TABLE_MAP.md](./DATABASE_TABLE_MAP.md) - Section: "Quick Reference: Key Relationships"

### "What issues have been found and fixed?"
→ Review: [SYSTEMATIC_AUDIT_SUMMARY.md](./SYSTEMATIC_AUDIT_SUMMARY.md)

---

## 📋 Document Purposes

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **DEVELOPER_SCHEMA_GUIDE** | Quick onboarding, common mistakes | First time working with schemas, or after a break |
| **SCHEMA_FIELD_REFERENCE** | Detailed field lookup | Writing queries, accessing schema fields |
| **DATABASE_TABLE_MAP** | Complete schema overview | Understanding relationships, planning features |
| **AUTH_STATUS_REPORT** | Authentication details | Working on auth, users, permissions |
| **SCHEMA_CONFORMANCE_AUDIT** | Validation findings | Understanding past issues, avoiding mistakes |
| **SYSTEMATIC_AUDIT_SUMMARY** | Audit results | Checking what's been fixed, validation status |

---

## 🎓 Reading Order for New Developers

### Day 1: Quick Start
1. [DEVELOPER_SCHEMA_GUIDE.md](./DEVELOPER_SCHEMA_GUIDE.md) - Read entire file (15 min)
2. [SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md) - Skim "Common Mistakes" section

### Day 2: Deep Dive
3. [DATABASE_TABLE_MAP.md](./DATABASE_TABLE_MAP.md) - Read relevant sections for your feature
4. [AUTH_STATUS_REPORT.md](./AUTH_STATUS_REPORT.md) - If working with authentication

### Ongoing: Reference
- Keep [SCHEMA_FIELD_REFERENCE.md](./SCHEMA_FIELD_REFERENCE.md) open while coding
- Bookmark for quick field lookups

---

## 🔄 Keeping Documentation Updated

### When to Update Documentation

**Always update when:**
- ✅ Adding new tables or fields
- ✅ Changing field names or types
- ✅ Adding new associations
- ✅ Finding schema issues

**Files to Update:**
1. **SCHEMA_FIELD_REFERENCE.md** - Add new field definitions
2. **DATABASE_TABLE_MAP.md** - Update schema mapping
3. Update "Last Updated" dates

### Update Process
```bash
# 1. Make schema changes
mix ecto.gen.migration your_migration
# Edit migration file
mix ecto.migrate

# 2. Update schema file
# Edit lib/shop1_cmms/<context>/<schema>.ex

# 3. Update documentation
# Edit docs/SCHEMA_FIELD_REFERENCE.md
# Edit docs/DATABASE_TABLE_MAP.md

# 4. Commit together
git add priv/repo/migrations/ lib/ docs/
git commit -m "feat: Add new field with documentation"
```

---

## 🛠️ Validation Tools

### Check for Schema Issues
```bash
# Compile with warnings
mix compile --warnings-as-errors

# Look for these warnings:
# - "invalid association"
# - "undefined function"
# - KeyError in tests
```

### Verify Field Names
```elixir
# In iex -S mix
YourSchema.__schema__(:fields)
```

### Database Query
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_table'
ORDER BY column_name;
```

---

## 📊 Documentation Coverage

### Current Status
- ✅ All 19 schemas documented
- ✅ All fields with correct types
- ✅ Common patterns documented
- ✅ Known issues documented
- ✅ Quick reference guides created

### Validation
- ✅ Verified against actual database
- ✅ All field names validated
- ✅ All associations checked
- ✅ ID types confirmed
- ✅ Timestamp types verified

---

## 💡 Pro Tips

### Tip 1: Search Before You Code
```bash
# Find field usage examples
grep -r "frequency_interval" lib/
```

### Tip 2: Use Documentation in Code
```elixir
# Reference docs in your code comments
# See docs/SCHEMA_FIELD_REFERENCE.md for field details
def calculate_next_due(schedule) do
  # Using frequency (enum) and frequency_interval (integer)
  # NOT frequency_value or frequency_unit (don't exist)
  ...
end
```

### Tip 3: Keep Docs Open
- Bookmark SCHEMA_FIELD_REFERENCE.md in your browser
- Open it in a split editor window
- Print the "Quick Reference Card" section

---

## 🆘 Getting Help

### Something Not Documented?
1. Check if field exists: `YourSchema.__schema__(:fields)`
2. Check database: `\d+ table_name` in psql
3. Search codebase for usage examples
4. Add to documentation if found!

### Found an Error?
1. Verify against database
2. Update documentation
3. Note in commit message: "docs: Fix incorrect field name in..."

---

## 📅 Maintenance Schedule

**Monthly:**
- Review for outdated information
- Check against recent migrations
- Verify examples still work

**After Major Changes:**
- Full audit of affected schemas
- Update all related documentation
- Test all examples

---

## 🎯 Goals

These documents aim to:
- ✅ Prevent schema mismatch errors
- ✅ Speed up development
- ✅ Reduce debugging time
- ✅ Maintain consistency
- ✅ Onboard developers faster

---

**Last Updated:** 2025-01-31  
**Next Review:** 2025-02-28 (or after schema changes)

---

## Quick Access Links

- 🚀 [New Developer Guide](./DEVELOPER_SCHEMA_GUIDE.md)
- 📖 [Field Reference](./SCHEMA_FIELD_REFERENCE.md)
- 🗺️ [Table Map](./DATABASE_TABLE_MAP.md)
- 🔐 [Auth Report](./AUTH_STATUS_REPORT.md)
- 🔍 [Audit Report](./SCHEMA_CONFORMANCE_AUDIT.md)
- ✅ [Audit Summary](./SYSTEMATIC_AUDIT_SUMMARY.md)
