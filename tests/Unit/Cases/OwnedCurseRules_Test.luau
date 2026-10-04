return function(t)
	local R=require(game.ServerScriptService.Server.Gameplay.OwnedCurseRules)
	local e=t.expect
	-- The user requires half of the catalog base price, rounded down.
	t.test('odd base price rounds sale down',function()e.equal(R.saleValue(245,.5),122)end)
	-- Common and Secret use the same centralized percentage.
	t.test('Secret sale uses catalog price',function()e.equal(R.saleValue(50000,.5),25000)end)
	-- Invalid server prices are rejected, never converted into a reward.
	t.test('negative price is rejected',function()e.throws(function()R.saleValue(-1,.5)end)end)
	-- A duplicated confirmation can be consumed only once.
	t.test('sale confirmation cannot be replayed',function()
		local q={token='a',uid='curse',userId=7,revision=4,expires=15}
		e.truthy(R.consumeQuote(q,'a','curse',7,4,10));e.falsy(R.consumeQuote(q,'a','curse',7,4,10))
	end)
	-- A quote cannot authorize a different owner.
	t.test('foreign owner cannot use quote',function()
		e.falsy(R.consumeQuote({token='a',uid='curse',userId=7,revision=4,expires=15},'a','curse',8,4,10))
	end)
	-- Moving or otherwise changing a Curse invalidates the previous quote.
	t.test('stale quote revision is rejected',function()
		e.falsy(R.consumeQuote({token='a',uid='curse',userId=7,revision=4,expires=15},'a','curse',7,5,10))
	end)
	-- An expired quote requires reviewing a new confirmation.
	t.test('expired quote is rejected',function()
		e.falsy(R.consumeQuote({token='a',uid='curse',userId=7,revision=4,expires=15},'a','curse',7,4,16))
	end)
	-- Carried, stolen and locked Curses cannot be sold.
	t.test('transport and theft prohibit management',function()
		e.falsy(R.canManage({ownerUserId=7,state='CARRYING',carrierUserId=7},7,'PLACED'))
		e.falsy(R.canManage({ownerUserId=7,state='PLACED',stealingUserId=8},7,'PLACED'))
		e.falsy(R.canManage({ownerUserId=7,state='PLACED',locked=true},7,'PLACED'))
	end)
	-- Only the physically carried instance can be placed in a free pedestal.
	t.test('placement requires carried instance and free destination',function()
		local r={uid='curse',ownerUserId=7,carrierUserId=7,state='CARRYING'}
		e.truthy(R.canPlace(r,7,'curse',nil));e.falsy(R.canPlace(r,7,'other',nil));e.falsy(R.canPlace(r,7,'curse','occupied'));e.falsy(R.canPlace(r,8,'curse',nil))
	end)
end
