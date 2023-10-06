@insert(
  note("add our own event listener for when an item is added to the inventory")
  file("game/components/inventoryComponent.ws")
  at(class CInventoryComponent)
  at(event OnItemAdded)
  below(ent = (CGameplayEntity)GetEntity())

)
RER_onItemAdded(this, data);

@replace(
  note("makes that repair kits repair 100% of the item's durability")
  at(class CR4Player)
  at(function RepairItemUsingConsumable)
  select(repairValue = max * itemValue /100;)
)
repairValue = max;