@insert(
  note("add our own event listener for when an item is equipped")
  at(class CInventoryComponent())
  at(function equipItem)
)
onEquipItem(this, item);

@replace(
  at(class CInput)
  at(private function onKeyDown)
)
public function onKeyDown