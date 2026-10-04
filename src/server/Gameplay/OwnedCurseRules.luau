-- Pure server rules shared by the service and useful race/state tests.
local Rules={}
function Rules.saleValue(basePrice,fraction)
	assert(typeof(basePrice)=='number' and basePrice>=0 and fraction>=0 and fraction<=1)
	return math.floor(basePrice*fraction)
end
function Rules.canManage(record,userId,state)
	return record~=nil and record.ownerUserId==userId and record.state==state
		and not record.locked and not record.stealingUserId and not record.carrierUserId
end
function Rules.canPlace(record,userId,carriedUid,occupied)
	return record~=nil and record.ownerUserId==userId and record.carrierUserId==userId
		and record.state=='CARRYING' and carriedUid==record.uid and not record.locked
		and not record.stealingUserId and occupied==nil
end
function Rules.consumeQuote(quote,token,uid,userId,revision,now)
	if not quote or quote.used or quote.token~=token or quote.uid~=uid
		or quote.userId~=userId or quote.revision~=revision or quote.expires<now then return false end
	quote.used=true
	return true
end
return Rules
