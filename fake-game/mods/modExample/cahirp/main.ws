@insert(
  note("makes that repair kits repair 100% of the item's durability")
  file(game/player/r4Player.ws)
  at(class CR4Player)
  at(function RepairItemUsingConsumable)
  select(repairValue = max * itemValue /100;)
)
// modFullRepair - BEGIN
repairValue = max;
// modFullRepair - END

@context(
  note("changes to the inventory component")
  file("game/components/inventoryComponent.ws")
  at(class CInventoryComponent)
)

@insert(
  note("add our own event listener for when an item is added to the inventory")
  at(event OnItemAdded)
  below(ent = (CGameplayEntity)GetEntity())

)
// modItemEquipEvent - BEGIN
RER_onItemAdded(this, data);
// modItemEquipEvent - END


@insert(
  at(function GetItemPrimaryStat)
  select[[
    if(attributeValue.valueBase != 0)
		{
			attributeVal = attributeValue.valueBase;
		}
		if(attributeValue.valueMultiplicative != 0)
		{
			attributeVal = attributeValue.valueMultiplicative;
		}
		if(attributeValue.valueAdditive != 0)
		{
			attributeVal = attributeValue.valueAdditive;
		}
  ]]
)
// modSomething - BEGIN
attributeVal = attributeValue.valueAdditive
// modSomething - END