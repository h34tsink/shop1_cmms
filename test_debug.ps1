# Run single test with debug
cd C:\working_copy\shop1_cmms
$env:MIX_ENV="test"
mix test test/shop1_cmms_web/live/metadata_live_test.exs:13 --trace 2>&1 | Select-String -Pattern "test PM Tags.*default|MatchError|redirect|user_id|tenant_id" | Select-Object -First 20
