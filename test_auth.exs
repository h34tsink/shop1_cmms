user = Shop1Cmms.Factory.insert_user_with_tenant(tenant_id: 1)
Shop1Cmms.Accounts.user_has_cmms_access?(user.id, 1)
