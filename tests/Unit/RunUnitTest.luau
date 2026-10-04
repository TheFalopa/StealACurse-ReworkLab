local expect={}
function expect.equal(a,b)assert(a==b,'Expected '..tostring(b)..', got '..tostring(a))end
function expect.truthy(a)assert(a,'Expected truthy')end
function expect.falsy(a)assert(not a,'Expected falsy')end
function expect.throws(fn)assert(not pcall(fn),'Expected rejection')end
return function(filter)
	local total={run=0,passed=0,failed=0}
	for _,module in script.Parent.Cases:GetChildren() do
		if not filter or module.Name:find(filter,1,true) then
			local t={expect=expect}
			function t.test(name,fn)
				total.run+=1;local ok,err=pcall(fn)
				if ok then total.passed+=1;print('[PASS] '..name)else total.failed+=1;warn('[FAIL] '..name..': '..tostring(err))end
			end
			require(module)(t)
		end
	end
	print('[SUMMARY]',total.run,total.passed,total.failed)
	return total
end
