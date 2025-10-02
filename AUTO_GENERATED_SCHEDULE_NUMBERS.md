# Auto-Generated PM Schedule Numbers

## Overview
PM Schedule numbers are now automatically generated when creating new PM schedules, eliminating manual entry errors and ensuring consistency.

## Format
**Format:** `PM-NNNNNNNN`

Where:
- `PM-` is the fixed prefix identifying the record as a PM Schedule
- `NNNNNNNN` is an 8-digit zero-padded sequential number

### Examples
- First schedule: `PM-00000001`
- Hundredth schedule: `PM-00000100`
- Millionth schedule: `PM-01000000`
- Maximum capacity: `PM-99999999` (99,999,999 schedules)

## Capacity
This format supports up to **99,999,999** PM schedules per tenant, which is well beyond typical CMMS requirements.

## Implementation Details

### Schema Changes
- The `schedule_number` field remains required in the database
- Auto-generation occurs in the changeset before validation
- Tenant-specific sequencing ensures each tenant has independent numbering

### Algorithm
1. Query the last schedule number for the tenant with pattern `PM-%`
2. Extract the numeric portion using regex
3. Increment by 1
4. Format with leading zeros to 8 digits
5. Prepend the `PM-` prefix

### Key Features
- **Tenant Isolation**: Each tenant has its own sequence starting from PM-00000001
- **Unique Constraint**: Database enforces uniqueness per tenant
- **No Gaps**: Sequential numbering without gaps (unless schedules are deleted)
- **Backwards Compatible**: Existing schedules retain their numbers
- **Edit Preserves Number**: When editing, the schedule number is displayed but not editable

## User Experience

### Creating a New PM Schedule
1. Click "New PM Schedule"
2. The form displays: "Schedule Number will be auto-generated in format: PM-00000001"
3. User fills in other required fields (Equipment, Title, Frequency)
4. Upon save, the system automatically assigns the next sequential number

### Editing an Existing PM Schedule
1. The schedule number is displayed in a blue info box at the top of the form
2. The number is read-only and cannot be changed
3. This prevents accidental renumbering and maintains audit trails

## Technical Files Modified

### 1. `/lib/shop1_cmms/maintenance/pm_schedule.ex`
- Added `maybe_generate_schedule_number/1` function to changeset pipeline
- Added `generate_schedule_number/1` private function
- Implements query logic to find last number and increment

### 2. `/lib/shop1_cmms_web/live/pm_schedules_live.ex`
- Updated form UI to show auto-generation message for new schedules
- Display current schedule number for existing schedules
- Changed "Asset" label to "Equipment" throughout
- Removed manual schedule_number input field

## Database Considerations

### Concurrency
The current implementation uses a "last + 1" approach which is suitable for most use cases. For high-concurrency environments, consider:
- Database sequences (if gaps are acceptable)
- Advisory locks (for gap-free sequences)
- Application-level locking

### Performance
- Query performance is optimal using indexed `schedule_number` field
- Uses pattern matching with `LIKE 'PM-%'` for tenant-specific sequences
- Order by DESC with LIMIT 1 ensures fast lookup

## Alternative Formats Considered

### PM-YYYYMMDD-NNNNNN
- **Pros**: Date context, easy to identify creation period
- **Cons**: More complex, requires date handling, potential for same-day conflicts

### PM-YYNN-NNNNNN  
- **Pros**: Year context, supports 999,999 per year
- **Cons**: Year rollover logic, less capacity

### PMS-NNNNNNNN
- **Pros**: Clear "Schedule" identifier
- **Cons**: One extra character, PM- is industry standard

## Testing

### Test Scenarios
1. ✅ Create first PM schedule → Should generate PM-00000001
2. ✅ Create second PM schedule → Should generate PM-00000002
3. ✅ Edit existing schedule → Should preserve original number
4. ✅ Multiple tenants → Each should have independent sequences
5. ✅ Validation → Should fail if schedule_number is manually duplicated

### Manual Testing
```elixir
# In IEx console:
alias Shop1Cmms.Maintenance
alias Shop1Cmms.Maintenance.PmSchedule

# Create a PM schedule - number should auto-generate
{:ok, schedule} = Maintenance.create_pm_schedule(%{
  title: "Test PM",
  frequency: :monthly,
  asset_id: "<asset_id>",
  tenant_id: 1
})

# Check the generated number
IO.inspect(schedule.schedule_number) # Should be "PM-00000001" or next in sequence
```

## Migration Path

### For Existing Deployments
1. Existing PM schedules retain their current schedule numbers
2. New schedules will auto-generate starting from the highest existing number + 1
3. If no existing schedules match the PM-NNNNNNNN pattern, starts at PM-00000001

### For New Deployments
- First PM schedule will be PM-00000001
- Subsequent schedules increment sequentially

## Future Enhancements

### Possible Improvements
1. **Custom Prefixes**: Allow tenants to customize prefix (e.g., "PMS-", "MAINT-")
2. **Reset Options**: Admin ability to reset sequence (with safeguards)
3. **Bulk Operations**: Optimize for bulk PM schedule creation
4. **Format Templates**: Support for different formatting patterns per tenant
5. **Archived Number Reuse**: Option to reuse numbers from deleted schedules

## Support and Maintenance

### Troubleshooting

**Issue**: Numbers are not sequential (gaps exist)
- **Cause**: Schedules were deleted
- **Resolution**: This is expected behavior; gaps indicate deleted records

**Issue**: "Schedule number already exists" error
- **Cause**: Race condition in concurrent creation
- **Resolution**: Retry the operation; consider adding advisory locks

**Issue**: Wrong sequence after migration
- **Cause**: Manual schedule numbers don't match PM-NNNNNNNN pattern
- **Resolution**: Query will skip non-matching patterns and start fresh sequence

## Related Documentation
- [PM Schedule System](./docs/PM_SCHEDULE_SYSTEM.md)
- [Work Orders](./docs/WORK_ORDERS.md)
- [Multi-Tenancy](./docs/MULTI_TENANCY.md)
