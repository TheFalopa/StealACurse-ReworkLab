local RS=game.ReplicatedStorage
local I=require(RS.Shared.ToolInventory);local M=require(RS.Shared.ToolEffectsMath);local L=require(RS.Shared.TheftLedgerMath)
return function(t)
 local E=t.expect
 local function inventory()local p={souls=321,curses={{uid='a',definitionId='cursed_doll',state='PLACED',pedestalId='slot_01'}},schema=1,revision=5};I.migrate(p);return p end
 t.test('tools migration preserves old money and collection',function()local p=inventory();E.equal(p.souls,321);E.equal(#p.curses,1);E.equal(p.revision,5);E.truthy(p.tools.owned.shovel);E.falsy(I.migrate(p))end)
 t.test('invalid saved inventory rejected without replacement',function()local p=inventory();p.tools.charges.impact_urn=0/0;local old=p.tools;E.throws(function()I.migrate(p)end);E.equal(p.tools,old)end)
 t.test('three equipped limit and duplicate equip',function()local s=inventory().tools;for _,id in {'ash_boots','mist_censer','exorcist_lantern'}do I.grant(s,id,1)end;E.truthy(I.equip(s,'ash_boots',true));E.truthy(I.equip(s,'mist_censer',true));E.falsy(I.equip(s,'exorcist_lantern',true));E.truthy(I.equip(s,'shovel',true));E.equal(#s.equipped,3)end)
 t.test('unowned item cannot equip; pass is explicit',function()local s=inventory().tools;E.falsy(I.equip(s,'jailer_chain',true));E.truthy(I.equip(s,'jailer_chain',true,true));E.falsy(s.owned.jailer_chain)end)
 t.test('finite consumable grants and charges',function()local s=inventory().tools;E.falsy(I.grant(s,'impact_urn',math.huge));E.falsy(I.grant(s,'impact_urn',-1));E.truthy(I.grant(s,'impact_urn',1));E.truthy(I.consume(s,'impact_urn'));E.falsy(I.consume(s,'impact_urn'));E.equal(s.charges.impact_urn,0)end)
 t.test('charge ceiling rejects without mutation',function()local s=inventory().tools;I.grant(s,'consecrated_salt',999);E.falsy(I.grant(s,'consecrated_salt',1));E.equal(s.charges.consecrated_salt,999)end)
 t.test('receipt replay does not grant twice',function()local s=inventory().tools;E.truthy(I.receipt(s,'studio:receipt','impact_urn',10));E.truthy(I.receipt(s,'studio:receipt','impact_urn',10));E.equal(s.charges.impact_urn,10);E.truthy(s.receipts['studio:receipt'])end)
 t.test('rejected receipt leaves no accepted marker',function()local s=inventory().tools;I.grant(s,'impact_urn',999);E.falsy(I.receipt(s,'pending','impact_urn',10));E.falsy(s.receipts.pending)end)
 t.test('effect expiration recomputes other slow and bonus',function()local s={a={slow=.65,expires=2},b={bonus=10,expires=4}};E.equal(M.speed(16,s,1),20.4);E.equal(M.speed(16,s,3),26);E.equal(M.speed(16,s,5),16)end)
 t.test('root expires and speed cannot stack above cap',function()local s={a={root=true,expires=2},b={bonus=90,expires=4}};E.equal(M.speed(16,s,1),0);E.equal(M.speed(16,s,3),28)end)
 t.test('nonfinite aim rejected',function()E.falsy(M.vector(Vector3.new(math.huge,0,0)));E.falsy(M.vector(Vector3.new(0/0,0,0)));E.falsy(M.vector('point'));E.truthy(M.vector(Vector3.new(12,4,8)))end)
 local op={uid='a',definitionId='cursed_doll',owner=1,from=1,phase='ATTEMPT',tx='x',revision=6}
 t.test('interrupted theft recovers original owner unplaced',function()local p=inventory();L.recover(p,1,{a=op});E.equal(#p.curses,1);E.equal(p.curses[1].state,'UNPLACED');E.equal(p.curses[1].pedestalId,nil);E.falsy(L.recover(p,1,{a=op}))end)
 t.test('committed transfer projects exactly one owner',function()local a=inventory();local b=inventory();b.curses={};local decision=table.clone(op);decision.owner=2;decision.phase='COMMITTED';L.recover(a,1,{a=decision});L.recover(b,2,{a=decision});L.recover(b,2,{a=decision});E.equal(#a.curses,0);E.equal(#b.curses,1);E.equal(b.curses[1].state,'UNPLACED')end)
 t.test('later sale is not resurrected by replay',function()local p=inventory();L.recover(p,1,{a=op});p.curses={};L.recover(p,1,{a=op});E.equal(#p.curses,0)end)
 t.test('subsequent theft excludes earlier owners',function()local p=inventory();local latest=table.clone(op);latest.tx='second';latest.owner=3;L.recover(p,1,{a=latest});E.equal(#p.curses,0)end)
 t.test('invalid journal stops recovery',function()E.throws(function()L.recover(inventory(),1,{a={uid='bad'}})end)end)
end
