/***********************************************************************/
/** Witcher Script file
/***********************************************************************/
/** Copyright © 2013-2014 CDProjektRed
/** Author : Dexio ?
/** 		 Bartosz Bigaj
/**			 Tomek Kozera
/***********************************************************************/

/*
enum EInventoryEventType
{
	IET_Empty,
	IET_ItemAdded,				// quantity always positive -> number of added items
	IET_ItemRemoved,			// quantity always positive -> number of removed items
	IET_ItemQuantityChanged,	// quantity positive or negative -> number of added (P) or removed (N) items
	IET_ItemTagChanged,			// quantity not used - always equal to 0
	IET_InventoryRebalanced,	// quantity not used - always equal to 0, itemId == INVALID
};
*/

class IInventoryScriptedListener
{
	event OnInventoryScriptedEvent( eventType : EInventoryEventType, itemId : SItemUniqueId, quantity : int, fromAssociatedInventory : bool ) {}
}

import struct SItemNameProperty
{
	import editable var itemName : name;
};

import struct SR4LootNameProperty
{
	import editable var lootName : name;
};

struct SItemExt
{
	editable var itemName : SItemNameProperty;
	editable var quantity : int;
		default quantity = 1;
};

struct SCardSourceData
{
	var cardName 	: name;
	var source 		: string;
	var originArea	: string;
	var originQuest	: string;
	var details		: string;
	var coords		: string;
};

//used to pass data about item being added/removed from inventory
import struct SItemChangedData
{
	import const var itemName : name;				//name of changed item
	import const var quantity : int;				//total quantity of item (e.g. if it's stackable item that spanned to several ids this is the total count)
	import const var informGui : bool;				//should UI be informed that the change occured
	import const var ids : array< SItemUniqueId >;	//array of ids of added items (e.g. when we add 3 swords we'll get 3 different ids OR when we add stackable item we might get few ids if quantity > stack size)
};

import class CInventoryComponent extends CComponent
{
	editable 		var priceMult			: float;
	editable 		var priceRepairMult		: float;
	editable 		var priceRepair			: float;
	editable 		var fundsType 			: EInventoryFundsType;

	private 		var recentlyAddedItems 	: array<SItemUniqueId>;
	private			var fundsMax			: int;
	private			var daysToIncreaseFunds	: int;

	default	priceMult = 1.0;
	default	priceRepairMult = 1.0;
	default	priceRepair = 10.0;
	default fundsType = EInventoryFunds_Avg;
	default daysToIncreaseFunds = 5;

	// ---------------------------------------------------------------------------
	// Funds Management
	// ---------------------------------------------------------------------------
	public function GetFundsType() : EInventoryFundsType
	{
		return fundsType;
	}

	public function GetDaysToIncreaseFunds() : int
	{
		return daysToIncreaseFunds;
	}

	public function GetFundsMax() : float
	{
		if ( EInventoryFunds_Broke == fundsType )
		{
			return 0;
		}
		else if ( EInventoryFunds_Avg == fundsType )
		{
			return 5000;
		}
		else if ( EInventoryFunds_Poor == fundsType )
		{
			return 2500;
		}
		else if ( EInventoryFunds_Rich == fundsType )
		{
			return 7500;
		}
		else if ( EInventoryFunds_RichQuickStart == fundsType )
		{
			return 15000;
		}
		return -1;
	}

	public function SetupFunds()
	{
		if ( EInventoryFunds_Broke == fundsType )
		{
			AddMoney( 0 );
		}
		else if ( EInventoryFunds_Poor == fundsType )
		{
			AddMoney( (int)( 200 * GetFundsModifier() ) );
		}
		else if ( EInventoryFunds_Avg == fundsType )
		{
			AddMoney( (int)( 500 * GetFundsModifier() ) );
		}
		else if ( EInventoryFunds_Rich == fundsType )
		{
			AddMoney( (int)( 1000 * GetFundsModifier() ) );
		}
		else if ( EInventoryFunds_RichQuickStart == fundsType )
		{
			AddMoney( (int)( 5000 * GetFundsModifier() ) );
		}
	}

	public function IncreaseFunds()
	{
		if ( GetMoney() < GetFundsMax() )
		{
			if ( EInventoryFunds_Avg == fundsType )
			{
				AddMoney( (int)( 150 * GetFundsModifier()) );
			}
			else if ( EInventoryFunds_Poor == fundsType )
			{
				AddMoney( (int)( 100 * GetFundsModifier() ) );
			}
			else if ( EInventoryFunds_Rich == fundsType )
			{
				AddMoney( (int)( 1000 * GetFundsModifier() ) );
			}
			else if ( EInventoryFunds_RichQuickStart == fundsType )
			{
				AddMoney( 1000 + (int)( 2500 * GetFundsModifier() ) );
			}
		}
	}

	public function GetMoney() : int
	{
		return GetItemQuantityByName( 'Crowns' );
	}
	
	public function SetMoney( amount : int )
	{
		var currentMoney : int;
		
		if ( amount >= 0 )
		{
			currentMoney = GetMoney();
			RemoveMoney( currentMoney );

			AddAnItem( 'Crowns', amount );
		}
	}

	public function AddMoney( amount : int )
	{
		if ( amount > 0 )
		{
			AddAnItem( 'Crowns', amount );
			
			if ( thePlayer == GetEntity() )
			{
				theTelemetry.LogWithValue( TE_HERO_CASH_CHANGED, amount );
			}
		}
	}
	
	public function RemoveMoney( amount : int )
	{
		if ( amount > 0 )
		{
			RemoveItemByName( 'Crowns', amount );
			
			if ( thePlayer == GetEntity() )
			{
				theTelemetry.LogWithValue( TE_HERO_CASH_CHANGED, -amount );
			}
		}
	}

	// ---------------------------------------------------------------------------
	// Items management
	// ---------------------------------------------------------------------------
	
	import final function GetItemAbilityAttributeValue( itemId : SItemUniqueId, attributeName : name, abilityName : name) : SAbilityAttributeValue;
	//gets item currently equiped in specifed slot or SItemUniqueId::INVALID if none
	import final function GetItemFromSlot( slotName : name ) : SItemUniqueId;
		
	// Check if item index is valid.
	import final function IsIdValid( itemId : SItemUniqueId ) : bool;

	// Returns number of items in the inventory
	import final function GetItemCount( optional useAssociatedInventory : bool /* = false */ ) : int;
	
	// Returns all names of items stored in the inventory instance.
	import final function GetItemsNames() : array< name >;
	
	// Get all items in form of unique id array
	import final function GetAllItems( out items : array< SItemUniqueId > );
	
	//Returns id of first item item found that have given name
	import public function GetItemId( itemName : name ) : SItemUniqueId;
	
	//Returns ids of items that have given name
	import public function GetItemsIds( itemName : name ) : array< SItemUniqueId >;
	
	// Get all items with given tag in form of unique id array
	import final function GetItemsByTag( tag : name ) : array< SItemUniqueId >;
	
	// Get all items of given category in form of unique id array
	import final function GetItemsByCategory( category : name ) : array< SItemUniqueId >;
	
	// Get the names and quantities of ingredients of given schematic
	import final function GetSchematicIngredients(itemName : SItemUniqueId, out quantity : array<int>, out names : array<name>); // #B crafting stuff, crafting doesn't work
	
	// Get the type name of the craftsman for specific item
	import final function GetSchematicRequiredCraftsmanType(craftName : SItemUniqueId) : name; // #B crafting stuff, crafting doesn't work
	
	// Get the level name of the craftsman for specific item
	import final function GetSchematicRequiredCraftsmanLevel(craftName : SItemUniqueId) : name; // #B crafting stuff, crafting doesn't work
    
    // Get amount of stacked items
    import final function GetNumOfStackedItems( itemUniqueId: SItemUniqueId ) : int;
	
	import final function InitInvFromTemplate( resource : CEntityTemplate );
	// ---------------------------------------------------------------------------
	// Items localisation
	// ---------------------------------------------------------------------------
	
	// Get localized name of the item using CName
	import final function GetItemLocalizedNameByName( itemName : CName ) : string;
	
	// Get items localized desription using CName
    import final function GetItemLocalizedDescriptionByName( itemName : CName ) : string;
    
	// Get localized name of the item using UniqueID
	import final function GetItemLocalizedNameByUniqueID( itemUniqueId : SItemUniqueId ) : string;
	
	// Get items localized desripption using UniqueID
    import final function GetItemLocalizedDescriptionByUniqueID( itemUniqueId : SItemUniqueId ) : string;
    
    // Get item icon using UniqeID
    import final function GetItemIconPathByUniqueID( itemUniqueId : SItemUniqueId ) : string;
    
    // Get item icon using CName
    import final function GetItemIconPathByName( itemName : CName ) : string;
    
    import final function AddSlot( itemUniqueId : SItemUniqueId ) : bool;
    
	import final function GetSlotItemsLimit( itemUniqueId : SItemUniqueId ) : int;
	
    import private final function BalanceItemsWithPlayerLevel( playerLevel : int );
    
    public function ForceSpawnItemOnStart( itemId : SItemUniqueId ) : bool	
	{
		return ItemHasTag(itemId, 'MutagenIngredient');
	}
	
    //gets total item armor including repair object bonuses and durability modifiers
    public final function GetItemArmorTotal(item : SItemUniqueId) : SAbilityAttributeValue
    {
		var armor, armorBonus : SAbilityAttributeValue;
		var durMult : float;
		
		armor = GetItemAttributeValue(item, theGame.params.ARMOR_VALUE_NAME);
		armorBonus = GetRepairObjectBonusValueForArmor(item);
		durMult = theGame.params.GetDurabilityMultiplier( GetItemDurabilityRatio(item), false);
		
		return armor * durMult + armorBonus;
    }
    
    public final function GetItemLevel(item : SItemUniqueId) : int
    {
		var itemCategory : name;
		var itemAttributes : array<SAbilityAttributeValue>;
		var itemName : name;
		var isWitcherGear : bool;
		var isRelicGear : bool;
		var level : int;
		
		itemCategory = GetItemCategory(item);
		itemName = GetItemName(item);
		
		isWitcherGear = false;
		isRelicGear = false;
		if ( RoundMath(CalculateAttributeValue( GetItemAttributeValue(item, 'quality' ) )) == 5 ) isWitcherGear = true;
		if ( RoundMath(CalculateAttributeValue( GetItemAttributeValue(item, 'quality' ) )) == 4 ) isRelicGear = true;
		
		switch(itemCategory)
		{
			case 'armor' :
			case 'boots' : 
			case 'gloves' :
			case 'pants' :
				itemAttributes.PushBack( GetItemAttributeValue(item, 'armor') );
				break;
				
			case 'silversword' :
				itemAttributes.PushBack( GetItemAttributeValue(item, 'SilverDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'BludgeoningDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'RendingDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'ElementalDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'FireDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'PiercingDamage') );
				break;
				
			case 'steelsword' :
				itemAttributes.PushBack( GetItemAttributeValue(item, 'SlashingDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'BludgeoningDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'RendingDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'ElementalDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'FireDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'SilverDamage') );
				itemAttributes.PushBack( GetItemAttributeValue(item, 'PiercingDamage') );
				break;
				
			case 'crossbow' :
				itemAttributes.PushBack( GetItemAttributeValue(item, 'attack_power') );
				break;
				 
			default :
				break;
		}
		
		level = theGame.params.GetItemLevel(itemCategory, itemAttributes, itemName);
		
		if ( isWitcherGear ) level = level - 2;
		if ( isRelicGear ) level = level - 1;
		if ( level < 1 ) level = 1;
		if ( ItemHasTag(item, 'OlgierdSabre') ) level = level - 3;
		if ( (isRelicGear || isWitcherGear) && ItemHasTag(item, 'EP1') ) level = level - 1;
		
		return level;
    }
    
    public function GetItemLevelColorById( itemId : SItemUniqueId ) : string
    {
		var color : string;
		
		if (GetItemLevel(itemId) <= thePlayer.GetLevel())
		{
			color = "<font color = '#A09588'>"; // gray		
		}
		else
		{
			color = "<font color = '#9F1919'>"; // red
		}
		
		return color;
    }
	
  	public function GetItemLevelColor( lvl_item : int ) : string
	{
		var color : string;

		if ( lvl_item > thePlayer.GetLevel() ) 
		{
			color = "<font color = '#9F1919'>"; // red
		} else
		{
			color = "<font color = '#A09588'>"; // gray
		}
		
		return color;
	}	
	
    public final function AutoBalanaceItemsWithPlayerLevel()
    {
		var playerLevel : int;

		playerLevel = thePlayer.GetLevel();

		if( playerLevel < 0 )
		{
			playerLevel = 0;
		}
		
		BalanceItemsWithPlayerLevel( playerLevel );
    }
    
    public function GetItemsByName(itemName : name) : array<SItemUniqueId>
    {
		var ret : array<SItemUniqueId>;
		var i : int;
    
		if(!IsNameValid(itemName))
			return ret;
			
		GetAllItems(ret);
		
		for(i=ret.Size()-1; i>=0; i-=1)
		{
			if(GetItemName(ret[i]) != itemName)
			{
				ret.EraseFast( i );
			}
		}
				
		return ret;
    }
    
    public final function GetSingletonItems() : array<SItemUniqueId>
    {
		return GetItemsByTag(theGame.params.TAG_ITEM_SINGLETON);
	}
	
	//returns a total quantity of items that have given name
	import final function GetItemQuantityByName( itemName : name, optional useAssociatedInventory : bool /* = false */, optional ignoreTags : array< name > ) : int;
	
	//returns a total quantity of items that have given category
	import final function GetItemQuantityByCategory( itemCategory : name, optional useAssociatedInventory : bool /* = false */, optional ignoreTags : array< name > ) : int;

	//returns a total quantity of items that have given tag
	import final function GetItemQuantityByTag( itemTag : name, optional useAssociatedInventory : bool /* = false */, optional ignoreTags : array< name > ) : int;

	//Returns amount of all items in inventory. Be aware that this will also count NoShow and NoDrop items!
	import final function GetAllItemsQuantity( optional useAssociatedInventory : bool /* = false */, optional ignoreTags : array< name > ) : int;

	//if the flag is set then the inventory can have any amount of items with NoShow and/or NoDrop tags but only those
	public function IsEmpty(optional bSkipNoDropNoShow : bool) : bool
	{
		var i : int;
		var itemIds : array<SItemUniqueId>;
		
		if(bSkipNoDropNoShow)
		{
			GetAllItems( itemIds );
			for( i = itemIds.Size() - 1; i >= 0; i -= 1 )
			{
				if( !ItemHasTag( itemIds[ i ],theGame.params.TAG_DONT_SHOW ) && !ItemHasTag( itemIds[ i ], 'NoDrop' ) )
				{
					return false;
				}
				else if ( ItemHasTag( itemIds[ i ], 'Lootable') )
				{
					return false;
				}
			}
			
			return true;
		}

		return GetItemCount() <= 0;
	}
		
	//Returns categories of all held items
	public function GetAllHeldAndMountedItemsCategories( out heldItems : array<name>, optional out mountedItems : array<name> )
	{
		var allItems : array<SItemUniqueId>;
		var i : int;
		
		GetAllItems(allItems);
		for(i=allItems.Size()-1; i >= 0; i-=1)
		{
			if ( IsItemHeld(allItems[i]) )
				heldItems.PushBack(GetItemCategory(allItems[i]));
			else if ( IsItemMounted(allItems[i]) )
				mountedItems.PushBack(GetItemCategory(allItems[i]));
		}
	}
	
	public function GetAllHeldItemsNames( out heldItems : array<name> )
	{
		var allItems : array<SItemUniqueId>;
		var i : int;
		
		GetAllItems(allItems);
		for(i=allItems.Size()-1; i >= 0; i-=1)
		{
			if ( IsItemHeld(allItems[i]) )
				heldItems.PushBack(GetItemName(allItems[i]));
		}
	}
	
	public function HasMountedItemByTag(tag : name) : bool
	{
		var i : int;
		var allItems : array<SItemUniqueId>;
		
		if(!IsNameValid(tag))
			return false;
			
		allItems = GetItemsByTag(tag);
		for(i=0; i<allItems.Size(); i+=1)
			if(IsItemMounted(allItems[i]))
				return true;
				
		return false;
	}
	
	public function HasHeldOrMountedItemByTag(tag : name) : bool
	{
		var i : int;
		var allItems : array<SItemUniqueId>;
		
		if(!IsNameValid(tag))
			return false;
			
		allItems = GetItemsByTag(tag);
		for(i=0; i<allItems.Size(); i+=1)
			if( IsItemMounted(allItems[i]) || IsItemHeld(allItems[i]) )
				return true;
				
		return false;
	}
	
	// Get inventory item from item id
	import final function GetItem( itemId : SItemUniqueId ) : SInventoryItem;
	
	// Get item name
	import final function GetItemName( itemId : SItemUniqueId ) : name;
	
	// Get item category
	import final function GetItemCategory( itemId : SItemUniqueId ) : name;
	
	// Get item class
	import final function GetItemClass( itemId : SItemUniqueId ) : EInventoryItemClass; // #B not used at all
	
	// Get tags of given item, returns false if index is not valid
	import final function GetItemTags( itemId : SItemUniqueId, out tags : array<name> ) : bool;

	// Get name of the item that can be crafted from given one
	import final function GetCraftedItemName( itemId : SItemUniqueId ) : name; // #B crafting stuff, check later
	
	// Get item price
	import final function TotalItemStats( invItem : SInventoryItem ) : float;

	import final function GetItemPrice( itemId : SItemUniqueId ) : int;

	// Get item price after item and vendor modifiers have been applied.
	import final function GetItemPriceModified( itemId : SItemUniqueId, optional playerSellingItem : Bool ) : int;

	// Get item price after item and vendor modifiers have been applied.
	import final function GetInventoryItemPriceModified( invItem : SInventoryItem, optional playerSellingItem : Bool ) : int;

	// Generates price per point of repair and total cost of repair for given item.
	import final function GetItemPriceRepair( invItem : SInventoryItem, out costRepairPoint : int, out costRepairTotal : int );	
	
	// Returns cost of removing an upgrade from given item.
	import final function GetItemPriceRemoveUpgrade( invItem : SInventoryItem ) : int;
	
	// Returns cost of disassembling a given item.
	import final function GetItemPriceDisassemble( invItem : SInventoryItem ) : int;
	
	// Returns cost of adding a slot to a given item.
	import final function GetItemPriceAddSlot( invItem : SInventoryItem ) : int;

	// Returns cost of adding a slot to a given item.
	import final function GetItemPriceCrafting( invItem : SInventoryItem ) : int;

	// Returns cost of disassembling a given item.
	import final function GetItemPriceEnchantItem( invItem : SInventoryItem ) : int;
	
	// Returns cost of disassembling a given item.
	import final function GetItemPriceRemoveEnchantment( invItem : SInventoryItem ) : int;
	
	import final function GetFundsModifier() : float;

	// Get item quantity by index
	import final function GetItemQuantity( itemId : SItemUniqueId ) : int;
	
	// Check if the item has given tag
	import final function ItemHasTag( itemId : SItemUniqueId, tag : name ) : bool;

	// Add tag to item - DOES NOT SAVE (it's a feature, not a bug)	
	import final function AddItemTag( itemId : SItemUniqueId, tag : name ) : bool;

	// Remove tag from item
	import final function RemoveItemTag( itemId : SItemUniqueId, tag : name ) : bool;
	
	//Manages tag on item - adds it of removes it
	public final function ManageItemsTag( items : array<SItemUniqueId>, tag : name, add : bool )
	{
		var i		: int;
		
		if( add )
		{
			for( i = 0 ; i < items.Size() ; i += 1 )
			{
				AddItemTag( items[ i ], tag );
			}
		}
		else
		{
			for( i = 0 ; i < items.Size() ; i += 1 )
			{
				RemoveItemTag( items[ i ], tag );
			}
		}
	}

	// Get item for which we have given itemEntity spawned
	import final function GetItemByItemEntity( itemEntity : CItemEntity ) : SItemUniqueId;  // #B not used at all
		
	//returns true if given item has given ability
	public function ItemHasAbility(item : SItemUniqueId, abilityName : name) : bool
	{
		var abilities : array<name>;
		
		GetItemAbilities(item, abilities);
		return abilities.Contains(abilityName);
	}
	
	import final function GetItemAttributeValue( itemId : SItemUniqueId, attributeName : name, optional abilityTags : array< name >, optional withoutTags : bool ) : SAbilityAttributeValue;
	
	// Get base attribute names from item.
	import final function GetItemBaseAttributes( itemId : SItemUniqueId, out attributes : array<name> );
	
	// Get all attribute names from item.
	import final function GetItemAttributes( itemId : SItemUniqueId, out attributes : array<name> );
	
	// Get abilities from item
	import final function GetItemAbilities( itemId : SItemUniqueId, out abilities : array<name> );
	
	// Get efects from abilities
	import final function GetItemContainedAbilities( itemId : SItemUniqueId, out abilities : array<name> );
	
	//returns abilities names of this item's ability which holds given attribute with specified value
	public function GetItemAbilitiesWithAttribute(id : SItemUniqueId, attributeName : name, attributeVal : float) : array<name>
	{
		var i : int;
		var abs, ret : array<name>;
		var dm : CDefinitionsManagerAccessor;
		var val : float;
		var min, max : SAbilityAttributeValue;
	
		GetItemAbilities(id, abs);
		dm = theGame.GetDefinitionsManager();
		
		for(i=0; i<abs.Size(); i+=1)
		{
			dm.GetAbilityAttributeValue(abs[i], attributeName, min, max);
			val = CalculateAttributeValue(GetAttributeRandomizedValue(min, max));
			
			if(val == attributeVal)
				ret.PushBack(abs[i]);
		}
		
		return ret;
	}
	public function GetItemAbilitiesWithTag( itemId : SItemUniqueId, tag : name, out abilities : array<name> )
	{
		var i : int;
		var dm : CDefinitionsManagerAccessor;
		var allAbilities : array<name>;
		
		dm = theGame.GetDefinitionsManager();
		GetItemAbilities(itemId, allAbilities);
		
		for(i=0; i<allAbilities.Size(); i+=1)
		{
			if(dm.AbilityHasTag(allAbilities[i], tag))
			{
				abilities.PushBack(allAbilities[i]);
			}
		}
	}
	
	// Transfer one item to other inventory ( holsters items if needed )
	// This has to be overriden in scripts because of custom updating of player item data OnReceive
	//    Use GiveItemTo() instead
	import private final function GiveItem( otherInventory : CInventoryComponent, itemId : SItemUniqueId, optional quantity : int ) : array<SItemUniqueId>;
	
	public final function GiveMoneyTo(otherInventory : CInventoryComponent, optional quantity : int, optional informGUI : bool )
	{
		var moneyId : array<SItemUniqueId>;
		
		moneyId = GetItemsByName('Crowns');
		GiveItemTo(otherInventory, moneyId[0], quantity, false, true, informGUI);
	}
	
	public final function GiveItemTo( otherInventory : CInventoryComponent, itemId : SItemUniqueId, optional quantity : int, optional refreshNewFlag : bool, optional forceTransferNoDrops : bool, optional informGUI : bool ) : SItemUniqueId
	{
		var arr : array<SItemUniqueId>;
		var itemName : name;
		var i : int;
		var uiData : SInventoryItemUIData;
		var isQuestItem : bool;
		
		//check quantity parameter
		if(quantity == 0)
			quantity = 1;
		
		quantity = Clamp(quantity, 0, GetItemQuantity(itemId));		
		if(quantity == 0)
			return GetInvalidUniqueId();
			
		itemName = GetItemName(itemId);
		//cannot pass items with NoDrop tag
		if(!forceTransferNoDrops && ( ItemHasTag(itemId, 'NoDrop') && !ItemHasTag(itemId, 'Lootable') ))
		{
			LogItems("Cannot transfer item <<" + itemName + ">> as it has the NoDrop tag set!!!");
			return GetInvalidUniqueId();
		}
		
		//there can be only one singleton item at a time of the same type		
		if(IsItemSingletonItem(itemId))
		{
			//player already has singleton - get id
			if(otherInventory == thePlayer.inv && otherInventory.GetItemQuantityByName(itemName) > 0)
			{
				LogAssert(false, "CInventoryComponent.GiveItemTo: cannot add singleton item as player already has this item!");
				return GetInvalidUniqueId();
			}
			//player does not have singleton - add one item and get id
			else
			{
				arr = GiveItem(otherInventory, itemId, quantity);
			}			
		}
		else
		{
			//transfer non-singleton items
			arr = GiveItem(otherInventory, itemId, quantity);
		}
		
		//custom code if player is given an item
		if(otherInventory == thePlayer.inv)
		{
			isQuestItem = this.IsItemQuest( itemId );
			theTelemetry.LogWithLabelAndValue(TE_INV_ITEM_PICKED, itemName, quantity);
			
			if ( !theGame.AreSavesLocked() && ( isQuestItem || this.GetItemQuality( itemId ) >= 4 ) )
			{
				theGame.RequestAutoSave( "item gained", false );
			}
		}
		
		if (refreshNewFlag)
		{
			for (i = 0; i < arr.Size(); i += 1)
			{
				uiData = otherInventory.GetInventoryItemUIData( arr[i] );
				uiData.isNew = true;
				otherInventory.SetInventoryItemUIData( arr[i], uiData );
			}
		}
		
		return arr[0];
	}
	
	public final function GiveAllItemsTo(otherInventory : CInventoryComponent, optional forceTransferNoDrops : bool, optional informGUI : bool)
	{
		var items : array<SItemUniqueId>;
		
		GetAllItems(items);
		GiveItemsTo(otherInventory, items, forceTransferNoDrops, informGUI);
	}
	
	public final function GiveItemsTo(otherInventory : CInventoryComponent, items : array<SItemUniqueId>, optional forceTransferNoDrops : bool, optional informGUI : bool) : array<SItemUniqueId>
	{
		var i : int;
		var ret : array<SItemUniqueId>;
		
		for( i = 0; i < items.Size(); i += 1 )
		{
			ret.PushBack(GiveItemTo(otherInventory, items[i], GetItemQuantity(items[i]), true, forceTransferNoDrops, informGUI));
		}
		
		return ret;
	}
		
	// If there is any item with the same name in inventory
	import final function HasItem( item : name ) : bool;
	
	// If there is specified item in inventory
	//TK: won't it be enough to check if ID is valid?
	final function HasItemById(id : SItemUniqueId) : bool
	{		
		var arr : array<SItemUniqueId>;
		
		GetAllItems(arr);
		return arr.Contains(id);
	}
	
	public function HasItemByTag(tag : name) : bool
	{
		var quantity : int;
		
		quantity = GetItemQuantityByTag( tag );
		return quantity > 0;
	}

	public function HasItemByCategory(category : name) : bool
	{
		var quantity : int;
		
		quantity = GetItemQuantityByCategory( category );
		return quantity > 0;
	}
	
	//returns true if has bolts with infinite ammo
	public function HasInfiniteBolts() : bool
	{
		var ids : array<SItemUniqueId>;
		var i : int;
		
		ids = GetItemsByTag(theGame.params.TAG_INFINITE_AMMO);
		for(i=0; i<ids.Size(); i+=1)
		{
			if(IsItemBolt(ids[i]))
			{
				return true;
			}
		}
		
		return false;
	}
	
	//returns true if has bolts with infinite ammo
	public function HasGroundBolts() : bool
	{
		var ids : array<SItemUniqueId>;
		var i : int;
		
		ids = GetItemsByTag(theGame.params.TAG_GROUND_AMMO);
		for(i=0; i<ids.Size(); i+=1)
		{
			if(IsItemBolt(ids[i]))
			{
				return true;
			}
		}
		
		return false;
	}
	
	//returns true if has bolts with underwater ammo
	public function HasUnderwaterBolts() : bool
	{
		var ids : array<SItemUniqueId>;
		var i : int;
		
		ids = GetItemsByTag(theGame.params.TAG_UNDERWATER_AMMO);
		for(i=0; i<ids.Size(); i+=1)
		{
			if(IsItemBolt(ids[i]))
			{
				return true;
			}
		}
		
		return false;
	}
	
	// Add specified item to inventory
	// due to performance we should call AddSingleItem when only 1 item is added to avoid passing dynamic arrays from code
	import private final function AddMultiItem( item : name, optional quantity : int, optional informGui : bool /* = true */, optional markAsNew : bool /* = false */, optional lootable : bool /* =true */ ) : array<SItemUniqueId>;
	import private final function AddSingleItem( item : name, optional informGui : bool /* = true */, optional markAsNew : bool /* = false */, optional lootable : bool /* =true */  ) : SItemUniqueId;
	
	/*
		Returns array of item ids of given items (more than 1 if quantity is big enough to split items into few stacks.
		If item is SingleInstanceItem then nothing is added, instead id of the item already in inventory is returned.
	*/
	public final function AddAnItem(item : name, optional quantity : int, optional dontInformGui : bool, optional dontMarkAsNew : bool, optional showAsRewardInUIHax : bool) : array<SItemUniqueId>
	{
		var arr : array<SItemUniqueId>;
		var i : int;
		var isReadableItem : bool;
		
		//there can be only one singleton item at a time of the same type
		if( theGame.GetDefinitionsManager().IsItemSingletonItem(item) && GetEntity() == thePlayer)			
		{
			if(GetItemQuantityByName(item) > 0)
			{
				arr = GetItemsIds(item);
			}
			else
			{
				arr.PushBack(AddSingleItem(item, !dontInformGui, !dontMarkAsNew));				
			}
			
			quantity = 1;			
		}
		else
		{
			if(quantity < 2 ) // #B quantity equals one, or quantity wasn't set, both means that is only one item to add
			{
				arr.PushBack(AddSingleItem(item, !dontInformGui, !dontMarkAsNew));
			}
			else	
			{
				arr = AddMultiItem(item, quantity, !dontInformGui, !dontMarkAsNew);
			}
		}
		
		//only do checks/show UI once - all items are the same
		if(this == thePlayer.GetInventory())
		{
			if(ItemHasTag(arr[0],'ReadableItem'))
				UpdateInitialReadState(arr[0]);
			
			//Gwint card are not displayed in inventory, looting them needs to show visible reward notification for minigames and containers - quest post 1.0 hax 
			if(showAsRewardInUIHax || ItemHasTag(arr[0],'GwintCard'))
				thePlayer.DisplayItemRewardNotification(GetItemName(arr[0]), quantity );
		}
		
		return arr;
	}
		
	// Remove item with specified index from inventory
	import final function RemoveItem( itemId : SItemUniqueId, optional quantity : int ) : bool;
	
	//internal function to remove requested quantity of items
	private final function InternalRemoveItems(ids : array<SItemUniqueId>, quantity : int)
	{
		var i, currQuantityToTake : int;
	
		//for each item stack
		for(i=0; i<ids.Size(); i+=1 )
		{			
			//collect the quantity of items in current stack, clamp it to remaining required quantity
			currQuantityToTake = Min(quantity, GetItemQuantity(ids[i]) );
			
			//If taken item is a gwint card remove it from collection as well
			if( GetEntity() == thePlayer )
			{
				GetWitcherPlayer().RemoveGwentCard( GetItemName(ids[i]) , currQuantityToTake);
			}			
			
			//remove items
			RemoveItem(ids[i], currQuantityToTake);
			
			//update remaining required quantity to take
			quantity -= currQuantityToTake;
			
			//if took enough then quit
			if ( quantity == 0 )
			{
				return;
			}
			
			//if took too much then call Houston...
			LogAssert(quantity>0, "CInventoryComponent.InternalRemoveItems(" + GetItemName(ids[i]) + "): somehow took too many items! Should be " + (-quantity) + " less... Investigate!");
		}
	}
	
	// if quantity <0 then removes all items from inventory
	// if quantity == 0 then removes only 1 item
	public function RemoveItemByName(itemName : name, optional quantity : int) : bool
	{
		var totalItemCount : int;
		var ids : array<SItemUniqueId>;
	
		//does not have that many items
		totalItemCount = GetItemQuantityByName(itemName);
		if(totalItemCount < quantity || quantity == 0)
		{
			return false;
		}
		
		if(quantity == 0)
		{
			quantity = 1;
		}
		else if(quantity < 0)
		{
			quantity = totalItemCount;
		}
		
		ids = GetItemsIds(itemName);
		
		if(GetEntity() == thePlayer && thePlayer.GetSelectedItemId() == ids[0] )
		{
			thePlayer.ClearSelectedItemId();
		}
		
		InternalRemoveItems(ids, quantity);
		
		return true;
	}
	
	// if quantity <0 then removes all items from inventory
	// if quantity == 0 then removes only 1 item
	public function RemoveItemByCategory(itemCategory : name, optional quantity : int) : bool
	{
		var totalItemCount : int;
		var ids : array<SItemUniqueId>;
		var selectedItemId : SItemUniqueId;
		var i : int;
	
		//does not have that many items
		totalItemCount = GetItemQuantityByCategory(itemCategory);
		if(totalItemCount < quantity)
		{
			return false;
		}
		
		if(quantity == 0)
		{
			quantity = 1;
		}
		else if(quantity < 0)
		{
			quantity = totalItemCount;
		}
		
		ids = GetItemsByCategory(itemCategory);
		
		if(GetEntity() == thePlayer)
		{
			selectedItemId = thePlayer.GetSelectedItemId();
			for(i=0; i<ids.Size(); i+=1)
			{
				if(selectedItemId == ids[i] )
				{
					thePlayer.ClearSelectedItemId();
					break;
				}
			}
		}
			
		InternalRemoveItems(ids, quantity);
		
		return true;
	}
	
	// if quantity <0 then removes all items from inventory
	// if quantity == 0 then removes only 1 item
	public function RemoveItemByTag(itemTag : name, optional quantity : int) : bool
	{
		var totalItemCount : int;
		var ids : array<SItemUniqueId>;
		var i : int;
		var selectedItemId : SItemUniqueId;
	
		//does not have that many items
		totalItemCount = GetItemQuantityByTag(itemTag);
		if(totalItemCount < quantity)
		{
			return false;
		}
		
		if(quantity == 0)
		{
			quantity = 1;
		}
		else if(quantity < 0)
		{
			quantity = totalItemCount;
		}
		
		ids = GetItemsByTag(itemTag);
		
		if(GetEntity() == thePlayer)
		{
			selectedItemId = thePlayer.GetSelectedItemId();
			for(i=0; i<ids.Size(); i+=1)
			{				
				if(selectedItemId == ids[i] ) 
				{
					thePlayer.ClearSelectedItemId();
					break;
				}
			}
		}
		
		InternalRemoveItems(ids, quantity);
		
		return true;
	}
	
	// Removes all items from inventory
	import final function RemoveAllItems();
	
	// USE WITH EXTREME CAUTION / ASK MARCIN GOLLENT
	import final function GetItemEntityUnsafe( itemId : SItemUniqueId ) : CItemEntity;
	
	// Spawn deployment item entity
	import final function GetDeploymentItemEntity( itemId : SItemUniqueId, optional position : Vector, optional rotation : EulerAngles, optional allocateIdTag : bool ) : CEntity;
	
	// Add specified item to inventory
	import final function MountItem( itemId : SItemUniqueId, optional toHand : bool, optional force : bool ) : bool;
	
	// Add specified item to inventory
	import final function UnmountItem( itemId : SItemUniqueId, optional destroyEntity : bool ) : bool;
	
	// Check if specified item is mounted to equip bone BUT if it is held in hand it will return false
	// use IsItemEquipped instead to get around this
	import final function IsItemMounted(  itemId : SItemUniqueId ) : bool;	
	
	// Check if specified item is held in hand - only a silver, steel sword or secondary weapon!
	// If item is held then it is not mounted!!!!!!!!!!
	import final function IsItemHeld(  itemId : SItemUniqueId ) : bool;	
	
	// Drop item
	import final function DropItem( itemId : SItemUniqueId, optional removeFromInv /*=false*/ : bool );
	
	// Returns the name of a hold slot defined for the item
	import final function GetItemHoldSlot( itemId : SItemUniqueId ) : name;
	
	// Play effect on item
	import final function PlayItemEffect( itemId : SItemUniqueId, effectName : name );
	import final function StopItemEffect( itemId : SItemUniqueId, effectName : name );
	
	// Throw away given item to a spawned container, returns true if succeded
	import final function ThrowAwayItem( itemId : SItemUniqueId, optional quantity : int ) : bool;
	
	// Throw away all items, returns entity created
	import final function ThrowAwayAllItems() : CEntity; // #B not used at all
	
	// Throw away items, excluding those with any of given tags, returns entity created
	import final function ThrowAwayItemsFiltered( excludedTags : array< name > ) : CEntity;

	// Throw away lootable items, returns entity created
	import final function ThrowAwayLootableItems( optional skipNoDropNoShow : bool ) : CEntity;
	
	// Get arrays of names and counts
	import final function GetItemRecyclingParts( itemId : SItemUniqueId ) : array<SItemParts>;
	
	import final function GetItemWeight( id : SItemUniqueId ) : float;
/*	{
		var weight : float;

		if( !IsIdValid( id ) )
			return 0;
		
		dm = theGame.GetDefinitionsManager();

		weight = -1;
		weight = dm.GetItemWeight( id );
		
		if ( weight == -1 )
		{
			return CalculateAttributeValue( GetItemAttributeValue( id, 'weight' ) );
		}

		return weight;
	}*/
	
	public final function HasQuestItem() : bool
	{
		var allItems		: array< SItemUniqueId >;
		var i				: int;
		
		allItems = GetItemsByTag('Quest');
		for ( i=0; i<allItems.Size(); i+=1 )
		{
			if(!ItemHasTag(allItems[i], theGame.params.TAG_DONT_SHOW))
			{
				return true;
			}
		}
		
		return false;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////  @DURABILITY  //////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Durability, -1 if has none or not set
	import final function HasItemDurability( itemId : SItemUniqueId ) : bool;
	import final function GetItemDurability( itemId : SItemUniqueId ) : float;
	import private final function SetItemDurability( itemId : SItemUniqueId, durability : float );
	import final function GetItemInitialDurability( itemId : SItemUniqueId ) : float;
	import final function GetItemMaxDurability( itemId : SItemUniqueId ) : float;
	import final function GetItemGridSize( itemId : SItemUniqueId ) : int;
		
		
	import final function NotifyItemLooted( item : SItemUniqueId );
	import final function ResetContainerData();
		
	public function SetItemDurabilityScript( itemId : SItemUniqueId, durability : float )
	{
		var oldDur : float;
	
		oldDur = GetItemDurability(itemId);
		
		if(oldDur == durability)
			return;
			
		if(durability < oldDur)
		{
			if ( ItemHasAbility( itemId, 'MA_Indestructible' ) )
			{
				return;
			}

			if(GetEntity() == thePlayer && ShouldProcessTutorial('TutorialDurability'))
			{
				if ( durability <= theGame.params.ITEM_DAMAGED_DURABILITY && oldDur > theGame.params.ITEM_DAMAGED_DURABILITY )
				{
					FactsAdd( "tut_item_damaged", 1 );
				}
			}
		}
			
		SetItemDurability( itemId, durability );		
	}
	
	//returns false if item durability could not be reduced (no durability at all or already at 0)
	public function ReduceItemDurability(itemId : SItemUniqueId, optional forced : bool) : bool
	{
		var dur, value, durabilityDiff, itemToughness, indestructible : float;
		var chance : int;
		if(!IsIdValid(itemId) || !HasItemDurability(itemId) || ItemHasAbility(itemId, 'MA_Indestructible'))
		{
			return false;
		}
		
		//get global stats
		if(IsItemWeapon(itemId))
		{	
			chance = theGame.params.DURABILITY_WEAPON_LOSE_CHANCE;
			value = theGame.params.GetWeaponDurabilityLoseValue();
		}
		else if(IsItemAnyArmor(itemId))
		{
			chance = theGame.params.DURABILITY_ARMOR_LOSE_CHANCE;			
			value = theGame.params.DURABILITY_ARMOR_LOSE_VALUE;
		}
		
		dur = GetItemDurability(itemId);
		
		if ( dur == 0 )
		{
			return false;
		}

		// Reduce durability
		if ( forced || RandRange( 100 ) < chance )
		{
			itemToughness = CalculateAttributeValue( GetItemAttributeValue( itemId, 'toughness' ) );
			indestructible = CalculateAttributeValue( GetItemAttributeValue( itemId, 'indestructible' ) );

			value = value * ( 1 - indestructible );

			if ( itemToughness > 0.0f && itemToughness <= 1.0f )
			{
				durabilityDiff = ( dur - value ) * itemToughness;
				
				SetItemDurabilityScript( itemId, MaxF(durabilityDiff, 0 ) );
			}
			else
			{
				SetItemDurabilityScript( itemId, MaxF( dur - value, 0 ) );
			}
		}

		return true;
	}

	public function GetItemDurabilityRatio(itemId : SItemUniqueId) : float
	{	
		if ( !IsIdValid( itemId ) || !HasItemDurability( itemId ) )
			return -1;
			
		return GetItemDurability(itemId) / GetItemMaxDurability(itemId);
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//gets item resistance value taking durability into consideration
	public function GetItemResistStatWithDurabilityModifiers(itemId : SItemUniqueId, stat : ECharacterDefenseStats, out points : SAbilityAttributeValue, out percents : SAbilityAttributeValue)
	{
		var mult : float;
		var null : SAbilityAttributeValue;
		
		points = null;
		percents = null;
		if(!IsItemAnyArmor(itemId))
			return;
	
		mult = theGame.params.GetDurabilityMultiplier(GetItemDurabilityRatio(itemId), false);
		
		points = GetItemAttributeValue(itemId, ResistStatEnumToName(stat, true));
		percents = GetItemAttributeValue(itemId, ResistStatEnumToName(stat, false));		
		
		points = points * mult;
		percents = percents * mult;
	}
	
	//returns list of resistance types that this item gives
	public function GetItemResistanceTypes(id : SItemUniqueId) : array<ECharacterDefenseStats>
	{
		var ret : array<ECharacterDefenseStats>;
		var i : int;
		var stat : ECharacterDefenseStats;
		var atts : array<name>;
		var tmpBool : bool;
	
		if(!IsIdValid(id))
			return ret;
			
		GetItemAttributes(id, atts);
		for(i=0; i<atts.Size(); i+=1)
		{
			stat = ResistStatNameToEnum(atts[i], tmpBool);
			if(stat != CDS_None && !ret.Contains(stat))
				ret.PushBack(stat);
		}
		
		return ret;
	}
	
	import final function GetItemModifierFloat( itemId : SItemUniqueId, modName : name, optional defValue : float ) : float;
	import final function SetItemModifierFloat( itemId : SItemUniqueId, modName : name, val : float);
	import final function GetItemModifierInt  ( itemId : SItemUniqueId, modName : name, optional defValue : int ) : int;	
	import final function SetItemModifierInt  ( itemId : SItemUniqueId, modName : name, val : int );
	
	// Adds quest_bonus tag to component tag list.
	import final function ActivateQuestBonus();

	// The Set name ( or empty if none exists )
	import final function GetItemSetName( itemId : SItemUniqueId ) : name;
	
	// Adds an ability to the item (for example - during crafting an item)
	import final function AddItemCraftedAbility( itemId : SItemUniqueId, abilityName : name, optional allowDuplicate : bool );
	
	// Removes a crafted ability from the item
	import final function RemoveItemCraftedAbility( itemId : SItemUniqueId, abilityName : name );
	
	//adds item ability
	import final function AddItemBaseAbility(item : SItemUniqueId, abilityName : name);
	
	//removes item ability
	import final function RemoveItemBaseAbility(item : SItemUniqueId, abilityName : name);
		
	// Destroy item
	import final function DespawnItem( itemId : SItemUniqueId ); // #B not used at all
	
	// ---------------------------------------------------------------------------
	// Weapons
	// ---------------------------------------------------------------------------
	
	// Get the inventory item ui data
	import final function GetInventoryItemUIData( item : SItemUniqueId ) : SInventoryItemUIData;
	
	// Set the inventory item ui data
	import final function SetInventoryItemUIData( item : SItemUniqueId, data : SInventoryItemUIData );
	
	import final function SortInventoryUIData(); // #B need to check C++ how it works, curently not used
	
	// ---------------------------------------------------------------------------
	// Debug
	// ---------------------------------------------------------------------------
	
	// Print contents of inventory
	import final function PrintInfo();

	// ---------------------------------------------------------------------------
	// Loot
	// ---------------------------------------------------------------------------

	// Enable generating loot
	import final function EnableLoot( enable : bool );

	// Test loot cache against loot definition. Add items if their respawn time elapsed
	import final function UpdateLoot();
	
	// Add items from specified loot definition
	import final function AddItemsFromLootDefinition( lootDefinitionName : name );
		
	// Check if loot contains items that need to be respawned
	import final function IsLootRenewable() : bool;
	
	// Check if loot will be renewed now (renew time expired)
	import final function IsReadyToRenew() : bool;
	
	// ---------------------------------------------------------------------------
	// Initialization
	// ---------------------------------------------------------------------------
	
	/**
		#B Called by player for tracking books
	*/
	function Created()
	{		
		LoadBooksDefinitions();
	}
	
	function ClearGwintCards()
	{
		var attr : SAbilityAttributeValue;
		var allItems : array<SItemUniqueId>;
		var card : array<SItemUniqueId>;
		var iHave, shopHave, cardLimit, delta : int;
		var curItem : SItemUniqueId;
		var i : int;
		
		allItems = GetItemsByCategory('gwint');
		for(i=allItems.Size()-1; i >= 0; i-=1)
		{	
			curItem = allItems[i];
			
			attr = GetItemAttributeValue( curItem, 'max_count');
			card = thePlayer.GetInventory().GetItemsByName( GetItemName( curItem ) );
			iHave = thePlayer.GetInventory().GetItemQuantity( card[0] );
			cardLimit = RoundF(attr.valueBase);
			shopHave = GetItemQuantity( curItem );
			
			if (iHave > 0 && shopHave > 0)
			{
				delta = shopHave - (cardLimit - iHave);
				
				if ( delta > 0 )
				{
					RemoveItem( curItem, delta );
				}
			}
		}
	}
	
	function ClearTHmaps()
	{
		var attr : SAbilityAttributeValue;
		var allItems : array<SItemUniqueId>;
		var map : array<SItemUniqueId>;
		var i : int;
		var thCompleted : bool;
		var iHave, shopHave : int;
		
		allItems = GetItemsByTag('ThMap');
		for(i=allItems.Size()-1; i >= 0; i-=1)
		{	
			attr = GetItemAttributeValue( allItems[i], 'max_count');
			map = thePlayer.GetInventory().GetItemsByName( GetItemName( allItems[i] ) );
			thCompleted = FactsDoesExist(GetItemName(allItems[i]));
			iHave = thePlayer.GetInventory().GetItemQuantity( map[0] );
			shopHave = RoundF(attr.valueBase);
			
			if ( iHave >= shopHave || thCompleted )
			{
				RemoveItem( allItems[i], GetItemQuantity(  allItems[i] ) );
			}
		}
	}
	
	//removes known recipe items (to be used inside shop inventory)
	public final function ClearKnownRecipes()
	{
		var witcher : W3PlayerWitcher;
		var recipes, craftRecipes : array<name>;
		var i : int;
		var itemName : name;
		var allItems : array<SItemUniqueId>;
		
		witcher = GetWitcherPlayer();
		if(!witcher)
			return;	//only witchers have recipes
		
		//get recipes
		recipes = witcher.GetAlchemyRecipes();
		craftRecipes = witcher.GetCraftingSchematicsNames();
		ArrayOfNamesAppend(recipes, craftRecipes);
		
		//get items
		GetAllItems(allItems);
		
		//filter
		for(i=allItems.Size()-1; i>=0; i-=1)
		{
			itemName = GetItemName(allItems[i]);
			if(recipes.Contains(itemName))
				RemoveItem(allItems[i], GetItemQuantity(allItems[i]));
		}
	}

	// ---------------------------------------------------------------------------
	// Books
	// ---------------------------------------------------------------------------

	function LoadBooksDefinitions() : void // #B
	{
		var readableArray : array<SItemUniqueId>;
		var i : int;
		
		readableArray = GetItemsByTag('ReadableItem');
		
		for( i = 0; i < readableArray.Size(); i += 1 )
		{
			if( IsBookRead(readableArray[i]))
			{
				continue;
			}
			UpdateInitialReadState(readableArray[i]);
		}
	}
	
	function UpdateInitialReadState( item : SItemUniqueId ) // #B
	{
		var abilitiesArray : array<name>;
		var i : int;
		GetItemAbilities(item,abilitiesArray);
			
		for( i = 0; i < abilitiesArray.Size(); i += 1 )
		{
			if( abilitiesArray[i] == 'WasRead' )
			{
				ReadBook(item);
				break;
			}
		}
	}
	
	function IsBookRead( item : SItemUniqueId ) : bool // #B
	{
		var bookName : name;
		var bResult : bool;
		
		bookName = GetItemName( item );
		
		bResult = IsBookReadByName( bookName ); //#B by name because it can be few different instances of one book
		return bResult;
	}
	
	function IsBookReadByName( bookName : name ) : bool // #B
	{
		var bookFactName : string;
		
		bookFactName = GetBookReadFactName( bookName );
		if( FactsDoesExist(bookFactName) )
		{
			return FactsQuerySum( bookFactName );
		}
		
		return false;
	}

	function ReadBook( item : SItemUniqueId, optional noNotification : bool ) //#B
	{
		//var mapManager : W3Common
		var bookName : name;
		var abilitiesArray : array<name>;
		var i : int;
		var commonMapManager : CCommonMapManager = theGame.GetCommonMapManager();		
		
		bookName = GetItemName( item );
		
		if ( !IsBookRead ( item ) && ItemHasTag ( item, 'FastTravel' ))
		{
			GetItemAbilities(item, abilitiesArray);
			
			for ( i = 0; i < abilitiesArray.Size(); i+=1 )
			{
				commonMapManager.SetEntityMapPinDiscoveredScript(true, abilitiesArray[i], true );
			}
		}
		ReadBookByNameId( bookName, item, false, noNotification );
		
		//RemoveItem(item);
		
		// Add perk associated with the book (M.J.)
		if(ItemHasTag(item, 'PerkBook'))
		{
			//TODO
		}	
	}
	
	public function GetBookText(item : SItemUniqueId) : string // #B
	{
		if ( GetItemName( item ) != 'Gwent Almanac' )
		{
			return ReplaceTagsToIcons(GetLocStringByKeyExt(GetItemLocalizedNameByUniqueID(item)+"_text")); 
		}
		else
		{
			return GetGwentAlmanacContents();
		}
	}
	
	public function GetBookTextByName( bookName : name ) : string
	{
		if( bookName != 'Gwent Almanac' ) 
		{
			return ReplaceTagsToIcons( GetLocStringByKeyExt( GetItemLocalizedNameByName( bookName ) + "_text" ) );
		}
		else
		{
			return GetGwentAlmanacContents();
		}
	}
	
	function ReadSchematicsAndRecipes( item : SItemUniqueId )
	{
		var itemCategory : name;
		var itemName : name;
		var player : W3PlayerWitcher;
		
		ReadBook( item );
		
		player = GetWitcherPlayer();
		if ( !player )
		{
			return;
		}

		itemName = GetItemName( item );
		itemCategory = GetItemCategory( item );
		if ( itemCategory == 'alchemy_recipe' )
		{
			if ( player.CanLearnAlchemyRecipe( itemName ) )
			{
				player.AddAlchemyRecipe( itemName );
				player.GetInventory().AddItemTag(item, 'NoShow');
				//theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("panel_hud_alchemyschematic_update_new_entry") );
			}
		}
		else if ( itemCategory == 'crafting_schematic' )
		{
			player.AddCraftingSchematic( itemName );
			player.GetInventory().AddItemTag(item, 'NoShow');
			//theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("panel_hud_craftingschematic_update_new_entry") );
		}
	}
	
	function ReadBookByName( bookName : name , unread : bool, optional noNotification : bool ) // #B 
	{
		var defMgr		 : CDefinitionsManagerAccessor;
		var bookFactName : string;
		
		if( IsBookReadByName( bookName ) != unread )
		{
			return;
		}
		
		bookFactName = "BookReadState_"+bookName;
		bookFactName = StrReplace(bookFactName," ","_");
		
		if( unread )
		{
			FactsSubstract( bookFactName, 1 );
		}
		else
		{
			FactsAdd( bookFactName, 1 );
			
			//reading achievement
			defMgr = theGame.GetDefinitionsManager();
			if(!IsAlchemyRecipe(bookName) && !IsCraftingSchematic(bookName) && !defMgr.ItemHasTag( bookName, 'Painting' ) )
			{
				theGame.GetGamerProfile().IncStat(ES_ReadBooks);
				
				if( !noNotification )
				{
					theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "notification_book_moved" ), 0, false );
				}
			}
			
			// Add bestiary entry from the book
			if ( AddBestiaryFromBook(bookName) )
				return;
			
				
			/*
			else if ( AddRecipePotionFromBook(bookName) )
				return;
			else if ( AddRecipeOilFromBook(bookName) )
				return;
			else if ( AddRecipePetardFromBook(bookName) )
				return;
			else if ( AddRecipeBoltFromBook(bookName) )
				return;
			else if ( AddRecipeSteelSwordFromBook(bookName) )
				return;
			else if ( AddRecipeSilverSwordFromBook(bookName) )
				return;
			else if ( AddRecipeRangedFromBook(bookName) )
				return;
			else if ( AddRecipeArmorFromBook(bookName) )
				return;
			else if ( AddRecipeBootsFromBook(bookName) )
				return;
			else if ( AddRecipePantsFromBook(bookName) )
				return;
			else if ( AddRecipeGlovesFromBook(bookName) )
				return;
			else if ( AddRecipeWitcherArmorsFromBook(bookName) )
				return;
			else if ( AddRecipeComponentFromBook(bookName) )
				return;
			else if ( AddRecipeUpgradeFromBook(bookName) )
				return;
			*/
		}
	}
	
	function ReadBookByNameId( bookName : name, itemId:SItemUniqueId, unread : bool, optional noNotification : bool ) // #B 
	{
		var bookFactName : string;
		
		if( IsBookReadByName( bookName ) != unread )
		{
			return;
		}
		
		bookFactName = "BookReadState_"+bookName;
		bookFactName = StrReplace(bookFactName," ","_");
		
		if( unread )
		{
			FactsSubstract( bookFactName, 1 );
		}
		else
		{
			FactsAdd( bookFactName, 1 );
			
			//reading achievement
			if( !IsAlchemyRecipe( bookName ) && !IsCraftingSchematic( bookName ) )
			{
				theGame.GetGamerProfile().IncStat(ES_ReadBooks);
				
				if( !noNotification )
				{					
					//theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "notification_book_moved" ), 0, false );
					GetWitcherPlayer().AddReadBook( bookName );
				}
			}
			
			// Add bestiary entry from the book
			if ( AddBestiaryFromBook(bookName) )
				return;
			else
				ReadSchematicsAndRecipes( itemId );
		}
	}
	
	
	private function AddBestiaryFromBook( bookName : name ) : bool
	{
		var i, j, r, len : int;
		var manager : CWitcherJournalManager;
		var resource : array<CJournalResource>;
		var entryBase : CJournalBase;
		var childGroups : array<CJournalBase>;
		var childEntries : array<CJournalBase>;
		var descriptionGroup : CJournalCreatureDescriptionGroup;
		var descriptionEntry : CJournalCreatureDescriptionEntry;
	
		manager = theGame.GetJournalManager();
		
		switch ( bookName )
		{
			case 'Beasts vol 1': 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWolf" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryDog" ) ); 
				break;
			case 'Beasts vol 2': 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryBear" ) ); 
				break;
			case 'Cursed Monsters vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWerewolf" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryLycanthrope" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 24');
				break;
			case 'Cursed Monsters vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWerebear" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryMiscreant" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 11');
				break;
			case 'Draconides vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryCockatrice" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryBasilisk" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 3');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 23');
				break;
			case 'Draconides vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWyvern" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryForktail" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 10');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 17');
				break;
			case 'Hybrid Monsters vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryHarpy" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryErynia" ) );
				resource.PushBack( (CJournalResource)LoadResource( "BestiarySiren" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiarySuccubus" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 14');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 21');
				break;
			case 'Hybrid Monsters vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGriffin" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 4');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 27');
				break;
			case 'Insectoids vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryEndriagaWorker" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryEndriagaTruten" ) );
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryEndriaga" ) );
				break;
			case 'Insectoids vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryCrabSpider" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryArmoredArachas" ) );
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryPoisonousArachas" ) );
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 2');
				break;
			case 'Magical Monsters vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGolem" ) ); 
				break;
			case 'Magical Monsters vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryElemental" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryIceGolem" ) );
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryFireElemental" ) );
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWhMinion" ) );
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 20');
				break;
			case 'Necrophage vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGhoul" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryAlghoul" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGreaterRotFiend" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryDrowner" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 15');
				break;
			case 'Necrophage vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGraveHag" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWaterHag" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryFogling" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 5');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 9');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 18');
				break;
			case 'Relict Monsters vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryBies" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryCzart" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 8');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 16');
				break;
			case 'Relict Monsters vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryLeshy" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiarySilvan" ) );
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 22');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 26');
				break;
			case 'Specters vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryMoonwright" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryNoonwright" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryPesta" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 6');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 13');
				break;
			case 'Specters vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWraith" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryHim" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 19');
				break;
			case 'Ogres vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryNekker" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryIceTroll" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryCaveTroll" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 12');
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 25');
				break;
			case 'Ogres vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryCyclop" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryIceGiant" ) ); 
				break;
			case 'Vampires vol 1':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryEkkima" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryHigherVampire" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 7');
				break;
			case 'Vampires vol 2':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryKatakan" ) ); 
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Mutagen 1');
				break;
			// EP2 books
			case 'bestiary_sharley_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiarySharley" ) ); 
				break;
			case 'bestiary_barghest_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryBarghest" ) ); 
				break;
			case 'bestiary_garkain_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryGarkain" ) ); 
				break;
			case 'bestiary_alp_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryAlp" ) ); 
				break;
			case 'bestiary_bruxa_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryBruxa" ) ); 
				break;
			case 'bestiary_spriggan_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiarySpriggan" ) ); 
				break;
			case 'bestiary_fleder_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryFleder" ) ); 
				break;
			case 'bestiary_wight_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryWicht" ) ); 
				break;
			case 'bestiary_dracolizard_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryDracolizard" ) ); 
				break;
			case 'bestiary_panther_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryPanther" ) ); 
				break;
			case 'bestiary_kikimore_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryKikimoraWarrior" ) ); 
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryKikimoraWorker" ) ); 
				break;
			case 'bestiary_scolopendromorph_book':
			case 'mq7023_fluff_book_scolopendromorphs':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryScolopendromorph" ) ); 
				break;
			case 'bestiary_archespore_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryArchespore" ) ); 
				break;
			case 'bestiary_protofleder_book':
				resource.PushBack( (CJournalResource)LoadResource( "BestiaryProtofleder" ) ); 
				break;
			default: 
				return false;
		}
		
		// alternatively instead of full path an alias used in LoadResource function i.e.
		//resource = (CJournalResource)LoadResource( "JournalBasilisk" );
		
		len = resource.Size();
		if( len > 0)
		{
			//inventory panel UI notification about new bestiary entry				
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "panel_hud_journal_entry_bestiary_new" ), 0, true );
			theSound.SoundEvent("gui_ingame_new_journal");
		}
		
		for (r=0; r < len; r += 1 )
		{
			if ( !resource[ r ] )
			{
				// missing resource
				continue;
			}
			entryBase = resource[r].GetEntry();
			if ( entryBase )
			{
				manager.ActivateEntry( entryBase, JS_Active );
				manager.SetEntryHasAdvancedInfo( entryBase, true );
				
				// additionally activate all description entries from description group
				manager.GetAllChildren( entryBase, childGroups );
				for ( i = 0; i < childGroups.Size(); i += 1 )
				{	
					descriptionGroup = ( CJournalCreatureDescriptionGroup )childGroups[ i ];
					if ( descriptionGroup )
					{
						manager.GetAllChildren( descriptionGroup, childEntries );
						for ( j = 0; j < childEntries.Size(); j += 1 )
						{
							descriptionEntry = ( CJournalCreatureDescriptionEntry )childEntries[ j ];
							if ( descriptionEntry )
							{
								manager.ActivateEntry( descriptionEntry, JS_Active );
							}
						}
						break;
					}
				}
			}
		}	
		
		if ( resource.Size() > 0 )
			return true;
		else
			return false;
	}
	
	/*
	private function AddRecipePotionFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Recipe for Black Blood 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Black Blood 1');
				return true;
			case 'Recipe for Black Blood 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Black Blood 2');
				return true;
			case 'Recipe for Black Blood 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Black Blood 3');
				return true;
				
			case 'Recipe for Blizzard 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Blizzard 1');
				return true;
			case 'Recipe for Blizzard 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Blizzard 2');
				return true;
			case 'Recipe for Blizzard 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Blizzard 3');
				return true;
				
			case 'Recipe for Cat 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cat 1');
				return true;
			case 'Recipe for Cat 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cat 2');
				return true;
			case 'Recipe for Cat 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cat 3');
				return true;
				
			case 'Recipe for Full Moon 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Full Moon 1');
				return true;
			case 'Recipe for Full Moon 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Full Moon 2');
				return true;
			case 'Recipe for Full Moon 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Full Moon 3');
				return true;
				
			case 'Recipe for Golden Oriole 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Golden Oriole 1');
				return true;
			case 'Recipe for Golden Oriole 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Golden Oriole 2');
				return true;
			case 'Recipe for Golden Oriole 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Golden Oriole 3');
				return true;
				
			case 'Recipe for Killer Whale 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Killer Whale 1');
				return true;
			case 'Recipe for Killer Whale 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Killer Whale 2');
				return true;
			case 'Recipe for Killer Whale 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Killer Whale 3');
				return true;
				
			case 'Recipe for Maribor Forest 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Maribor Forest 1');
				return true;
			case 'Recipe for Maribor Forest 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Maribor Forest 2');
				return true;
			case 'Recipe for Maribor Forest 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Maribor Forest 3');
				return true;
				
			case 'Recipe for Petris Philtre 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Petris Philtre 1');
				return true;
			case 'Recipe for Petris Philtre 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Petris Philtre 2');
				return true;
			case 'Recipe for Petris Philtre 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Petris Philtre 3');
				return true;
				
			case 'Recipe for Swallow 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Swallow 1');
				return true;	
			case 'Recipe for Swallow 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Swallow 2');
				return true;	
			case 'Recipe for Swallow 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Swallow 3');
				return true;	
				
			case 'Recipe for Tawny Owl 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Tawny Owl 1');
				return true;	
			case 'Recipe for Tawny Owl 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Tawny Owl 2');
				return true;	
			case 'Recipe for Tawny Owl 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Tawny Owl 3');
				return true;
				
			case 'Recipe for Thunderbolt 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Thunderbolt 1');
				return true;		
			case 'Recipe for Thunderbolt 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Thunderbolt 2');
				return true;	
			case 'Recipe for Thunderbolt 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Thunderbolt 3');
				return true;	

			case 'Recipe for White Honey 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Honey 1');
				return true;	
			case 'Recipe for White Honey 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Honey 2');
				return true;	
			case 'Recipe for White Honey 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Honey 3');
				return true;	
				
			case 'Recipe for White Raffard Decoction 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Raffards Decoction 1');
				return true;	
			case 'Recipe for White Raffard Decoction 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Raffards Decoction 2');
				return true;	
			case 'Recipe for White Raffard Decoction 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Raffards Decoction 3');
				return true;	
				
			case 'Recipe for Drowner Pheromone Potion 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Drowner Pheromone Potion 1');
				return true;	
				
			default:
				return false;
		}
	}
	
	private function AddRecipeOilFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Recipe for Beast Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Beast Oil 1');
				return true;
			case 'Recipe for Beast Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Beast Oil 2');
				return true;
			case 'Recipe for Beast Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Beast Oil 3');
				return true;
				
			case 'Recipe for Cursed Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cursed Oil 1');
				return true;
			case 'Recipe for Cursed Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cursed Oil 2');
				return true;
			case 'Recipe for Cursed Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Cursed Oil 3');
				return true;
			
			case 'Recipe for Hanged Man Venom 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hanged Man Venom 1');
				return true;
			case 'Recipe for Hanged Man Venom 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hanged Man Venom 2');
				return true;
			case 'Recipe for Hanged Man Venom 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hanged Man Venom 3');
				return true;
				
			case 'Recipe for Hybrid Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hybrid Oil 1');
				return true;
			case 'Recipe for Hybrid Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hybrid Oil 2');
				return true;
			case 'Recipe for Hybrid Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Hybrid Oil 3');
				return true;
				
			case 'Recipe for Insectoid Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Insectoid Oil 1');
				return true;
			case 'Recipe for Insectoid Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Insectoid Oil 2');
				return true;
			case 'Recipe for Insectoid Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Insectoid Oil 3');
				return true;
				
			case 'Recipe for Magicals Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Magicals Oil 1');
				return true;
			case 'Recipe for Magicals Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Magicals Oil 2');
				return true;
			case 'Recipe for Magicals Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Magicals Oil 3');
				return true;
				
			case 'Recipe for Necrophage Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Necrophage Oil 1');
				return true;
			case 'Recipe for Necrophage Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Necrophage Oil 2');
				return true;
			case 'Recipe for Necrophage Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Necrophage Oil 3');
				return true;
			
			case 'Recipe for Specter Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Specter Oil 1');
				return true;
			case 'Recipe for Specter Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Specter Oil 2');
				return true;
			case 'Recipe for Specter Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Specter Oil 3');
				return true;
				
			case 'Recipe for Vampire Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Vampire Oil 2');
				return true;
			case 'Recipe for Vampire Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Vampire Oil 2');
				return true;
			case 'Recipe for Vampire Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Vampire Oil 3');
				return true;
				
			case 'Recipe for Draconide Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Draconide Oil 1');
				return true;
			case 'Recipe for Draconide Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Draconide Oil 2');
				return true;
			case 'Recipe for Draconide Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Draconide Oil 3');
				return true;
				
			case 'Recipe for Ogre Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Ogre Oil 1');
				return true;
			case 'Recipe for Ogre Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Ogre Oil 2');
				return true;
			case 'Recipe for Ogre Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Ogre Oil 3');
				return true;
				
			case 'Recipe for Relic Oil 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Relic Oil 1');
				return true;
			case 'Recipe for Relic Oil 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Relic Oil 2');
				return true;
			case 'Recipe for Relic Oil 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Relic Oil 3');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipePetardFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Recipe for Dancing Star 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dancing Star 1');
				return true;
			case 'Recipe for Dancing Star 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dancing Star 2');
				return true;
			case 'Recipe for Dancing Star 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dancing Star 3');
				return true;
				
			case 'Recipe for Devils Puffball 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Devils Puffball 1');
				return true;
			case 'Recipe for Devils Puffball 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Devils Puffball 2');
				return true;
			case 'Recipe for Devils Puffball 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Devils Puffball 3');
				return true;
			
			case 'Recipe for Dwimeritium Bomb 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dwimeritium Bomb 1');
				return true;
			case 'Recipe for Dwimeritium Bomb 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dwimeritium Bomb 2');
				return true;
			case 'Recipe for Dwimeritium Bomb 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dwimeritium Bomb 3');
				return true;
				
			case 'Recipe for Dragons Dream 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dragons Dream 1');
				return true;
			case 'Recipe for Dragons Dream 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dragons Dream 2');
				return true;
			case 'Recipe for Dragons Dream 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Dragons Dream 3');
				return true;
				
			case 'Recipe for Grapeshot 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Grapeshot 1');
				return true;
			case 'Recipe for Grapeshot 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Grapeshot 2');
				return true;
			case 'Recipe for Grapeshot 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Grapeshot 3');
				return true;
				
			case 'Recipe for Samum 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Samum 1');
				return true;
			case 'Recipe for Samum 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Samum 2');
				return true;
			case 'Recipe for Samum 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Samum 3');
				return true;
			
			case 'Recipe for Silver Dust Bomb 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Silver Dust Bomb 1');
				return true;
			case 'Recipe for Silver Dust Bomb 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Silver Dust Bomb 2');
				return true;
			case 'Recipe for Silver Dust Bomb 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for Silver Dust Bomb 3');
				return true;
				
			case 'Recipe for White Frost 1':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Frost 1');
				return true;
			case 'Recipe for White Frost 2':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Frost 2');
				return true;
			case 'Recipe for White Frost 3':
				GetWitcherPlayer().AddAlchemyRecipe('Recipe for White Frost 3');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeBoltFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Bodkin Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bodkin Bolt schematic');
				return true;
			case 'Blunt Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Blunt Bolt schematic');
				return true;
			case 'Broadhead Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Broadhead Bolt schematic');
				return true;
			case 'Target Point Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Target Point Bolt schematic');
				return true;
			case 'Split Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Split Bolt schematic');
				return true;
			case 'Explosive Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Explosive Bolt schematic');
				return true;
			case 'Bait Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bait Bolt schematic');
				return true;
			case 'Tracking Bolt schematic':
				GetWitcherPlayer().AddCraftingSchematic('Tracking Bolt schematic');
				return true;
				
			default:
				return false;
		}
	}
	
	private function AddRecipeSteelSwordFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Short sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Short sword 1 schematic');
				return true;
			case 'Short sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Short sword 2 schematic');
				return true;
			case 'No Mans Land sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('No Mans Land sword 1 schematic');
				return true;
			case 'No Mans Land sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('No Mans Land sword 2 schematic');
				return true;
			case 'Skellige sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Skellige sword 1 schematic');
				return true;
			case 'Lynx School steel sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School steel sword schematic');
				return true;
			case 'Nilfgaardian sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Nilfgaardian sword 1 schematic');
				return true;
			case 'Novigraadan sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Novigraadan sword 1 schematic');
				return true;
			case 'No Mans Land sword 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('No Mans Land sword 3 schematic');
				return true;
			case 'Skellige sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Skellige sword 2 schematic');
				return true;
			case 'Gryphon School steel sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School steel sword schematic');
				return true;
			case 'No Mans Land sword 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('No Mans Land sword 4 schematic');
				return true;
			case 'Scoiatael sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Scoiatael sword 2 schematic');
				return true;	
			case 'Novigraadan sword 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Novigraadan sword 4 schematic');
				return true;	
			case 'Nilfgaardian sword 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Nilfgaardian sword 4 schematic');
				return true;	
			case 'Scoiatael sword 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Scoiatael sword 3 schematic');
				return true;
			case 'Inquisitor sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Inquisitor sword 1 schematic');
				return true;
			case 'Bear School steel sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear School steel sword schematic');
				return true;
			case 'Wolf School steel sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School steel sword schematic');
				return true;
			case 'Inquisitor sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Inquisitor sword 2 schematic');
				return true;
			case 'Dwarven sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dwarven sword 1 schematic');
				return true;
			case 'Dwarven sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dwarven sword 2 schematic');
				return true;
			case 'Gnomish sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gnomish sword 1 schematic');
				return true;
			case 'Gnomish sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gnomish sword 2 schematic');
				return true;
			case 'Viper Steel sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Viper Steel sword schematic');
				return true;
				
			// Relic steel swords
			case 'Arbitrator schematic':
				GetWitcherPlayer().AddCraftingSchematic('Arbitrator schematic');
				return true;
			case 'Beannshie schematic':
				GetWitcherPlayer().AddCraftingSchematic('Beannshie schematic');
				return true;
			case 'Blackunicorn schematic':
				GetWitcherPlayer().AddCraftingSchematic('Blackunicorn schematic');
				return true;
			case 'Longclaw schematic':
				GetWitcherPlayer().AddCraftingSchematic('Longclaw schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeSilverSwordFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Viper Silver sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Viper Silver sword schematic');
				return true;
			case 'Silver sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 1 schematic');
				return true;
			case 'Silver sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 2 schematic');
				return true;
			case 'Lynx School silver sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School silver sword schematic');
				return true;
			case 'Silver sword 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 3 schematic');
				return true;
			case 'Gryphon School silver sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School silver sword schematic');
				return true;
			case 'Silver sword 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 4 schematic');
				return true;
			case 'Silver sword 6 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 6 schematic');
				return true;
			case 'Silver sword 7 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Silver sword 7 schematic');
				return true;
			case 'Elven silver sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Elven silver sword 1 schematic');
				return true;
			case 'Bear School silver sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear School silver sword schematic');
				return true;
			case 'Elven silver sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Elven silver sword 2 schematic');
				return true;
			case 'Wolf School silver sword schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School silver sword schematic');
				return true;
			case 'Dwarven silver sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dwarven silver sword 1 schematic');
				return true;
			case 'Dwarven silver sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dwarven silver sword 2 schematic');
				return true;
			case 'Gnomish silver sword 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gnomish silver sword 1 schematic');
				return true;
			case 'Gnomish silver sword 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gnomish silver sword 2 schematic');
				return true;
			
			// Relic silver swords
			case 'Harpy schematic':
				GetWitcherPlayer().AddCraftingSchematic('Harpy schematic');
				return true;
			case 'Negotiator schematic':
				GetWitcherPlayer().AddCraftingSchematic('Negotiator schematic');
				return true;
			case 'Weeper schematic':
				GetWitcherPlayer().AddCraftingSchematic('Weeper schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeRangedFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Bear School Crossbow schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear School Crossbow schematic');
				return true;
			case 'Lynx School Crossbow schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School Crossbow schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeArmorFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Light Armor 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 1 schematic');
				return true;
			case 'Light Armor 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 2 schematic');
				return true;
			case 'Light Armor 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 3 schematic');
				return true;
			case 'Light Armor 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 4 schematic');
				return true;
			case 'Light Armor 5 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 5 schematic');
				return true;
			case 'Light Armor 6 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 6 schematic');
				return true;
			case 'Light Armor 7 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 7 schematic');
				return true;
			case 'Light Armor 8 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Light Armor 8 schematic');
				return true;
			case 'Medium Armor 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Medium Armor 1 schematic');
				return true;
			case 'Medium Armor 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Medium Armor 2 schematic');
				return true;
			case 'Medium Armor 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Medium Armor 3 schematic');
				return true;
			case 'Medium Armor 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Medium Armor 4 schematic');
				return true;
			case 'Heavy Armor 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Armor 1 schematic');
				return true;
			case 'Heavy Armor 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Armor 2 schematic');
				return true;
			case 'Heavy Armor 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Armor 3 schematic');
				return true;
			case 'Heavy Armor 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Armor 4 schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeBootsFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Boots 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Boots 1 schematic');
				return true;
			case 'Boots 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Boots 2 schematic');
				return true;
			case 'Boots 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Boots 3 schematic');
				return true;
			case 'Boots 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Boots 4 schematic');
				return true;
			case 'Heavy Boots 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Boots 1 schematic');
				return true;
			case 'Heavy Boots 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Boots 2 schematic');
				return true;
			case 'Heavy Boots 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Boots 3 schematic');
				return true;
			case 'Heavy Boots 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Boots 4 schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipePantsFromBook( bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Pants 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Pants 1 schematic');
				return true;
			case 'Pants 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Pants 2 schematic');
				return true;
			case 'Pants 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Pants 3 schematic');
				return true;
			case 'Pants 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Pants 4 schematic');
				return true;
			case 'Heavy Pants 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Pants 1 schematic');
				return true;
			case 'Heavy Pants 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Pants 2 schematic');
				return true;
			case 'Heavy Pants 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Pants 3 schematic');
				return true;
			case 'Heavy Pants 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Pants 4 schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeGlovesFromBook(bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Gloves 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gloves 1 schematic');
				return true;
			case 'Gloves 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gloves 2 schematic');
				return true;
			case 'Gloves 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gloves 3 schematic');
				return true;
			case 'Gloves 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gloves 4 schematic');
				return true;
			case 'Heavy Gloves 1 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Gloves1 schematic');
				return true;
			case 'Heavy Gloves 2 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Gloves 2 schematic');
				return true;
			case 'Heavy Gloves 3 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Gloves 3 schematic');
				return true;
			case 'Heavy Gloves 4 schematic':
				GetWitcherPlayer().AddCraftingSchematic('Heavy Gloves 4 schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeWitcherArmorsFromBook(bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Lynx Armor schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx Armor schematic');
				return true;
			case 'Lynx Boots schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx Boots schematic');
				return true;
			case 'Lynx Gloves schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx Gloves schematic');
				return true;
			case 'Lynx Pants schematic':
				GetWitcherPlayer().AddCraftingSchematic('Lynx Pants schematic');
				return true;
			case 'Gryphon Armor schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon Armor schematic');
				return true;
			case 'Gryphon Boots schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon Boots schematic');
				return true;
			case 'Gryphon Gloves schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon Gloves schematic');
				return true;
			case 'Gryphon Pants schematic':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon Pants schematic');
				return true;
			case 'Bear Armor schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear Armor schematic');
				return true;
			case 'Bear Boots schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear Boots schematic');
				return true;
			case 'Bear Gloves schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear Gloves schematic');
				return true;
			case 'Bear Pants schematic':
				GetWitcherPlayer().AddCraftingSchematic('Bear Pants schematic');
				return true;
			case 'Wolf Armor schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf Armor schematic');
				return true;
			case 'Wolf Boots schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf Boots schematic');
				return true;
			case 'Wolf Gloves schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf Gloves schematic');
				return true;
			case 'Wolf Pants schematic':
				GetWitcherPlayer().AddCraftingSchematic('Wolf Pants schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeComponentFromBook(bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Steel ingot schematic':
				GetWitcherPlayer().AddCraftingSchematic('Steel ingot schematic');
				return true;
			case 'Dark Iron ingot schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dark Iron ingot schematic');
				return true;
			case 'Meteorite ingot schematic':
				GetWitcherPlayer().AddCraftingSchematic('Meteorite ingot schematic');
				return true;
			case 'Dwimeryte ingot schematic':
				GetWitcherPlayer().AddCraftingSchematic('Dwimeryte ingot schematic');
				return true;
			case 'Silver ingot schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Silver ingot schematic 1');
				return true;
			case 'Silver ingot schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Silver ingot schematic 2');
				return true;
			case 'Silver ingot schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Silver ingot schematic 3');
				return true;
			case 'Hardened leather schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Hardened leather schematic 1');
				return true;
			case 'Hardened leather schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Hardened leather schematic 2');
				return true;
			case 'Hardened leather schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Hardened leather schematic 3');
				return true;
			case 'Hardened leather schematic 4':
				GetWitcherPlayer().AddCraftingSchematic('Hardened leather schematic 4');
				return true;
			case 'Hardened timber schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Hardened timber schematic 1');
				return true;
			case 'Draconide leather schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Draconide leather schematic 1');
				return true;
			case 'Draconide leather schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Draconide leather schematic 2');
				return true;
			case 'Draconide leather schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Draconide leather schematic 3');
				return true;
			case 'Draconide leather schematic 4':
				GetWitcherPlayer().AddCraftingSchematic('Draconide leather schematic 4');
				return true;
			case 'Leather schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 1');
				return true;
			case 'Leather schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 2');
				return true;
			case 'Leather schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 3');
				return true;
			case 'Leather schematic 4':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 4');
				return true;
			case 'Leather schematic 5':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 5');
				return true;
			case 'Leather schematic 6':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 6');
				return true;
			case 'Leather schematic 7':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 7');
				return true;
			case 'Leather schematic 8':
				GetWitcherPlayer().AddCraftingSchematic('Leather schematic 8');
				return true;
			case 'Leather straps schematic':
				GetWitcherPlayer().AddCraftingSchematic('Leather straps schematic');
				return true;
			case 'Steel plates schematic':
				GetWitcherPlayer().AddCraftingSchematic('Steel plates schematic');
				return true;
			
			default:
				return false;
		}
	}
	
	private function AddRecipeUpgradeFromBook(bookName : name ) : bool
	{
		switch ( bookName )
		{
			case 'Starting Armor Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Starting Armor Upgrade schematic 1');
				return true;
				
			case 'Witcher Bear Jacket Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Jacket Upgrade schematic 1');
				return true;
			case 'Witcher Bear Jacket Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Jacket Upgrade schematic 2');
				return true;
			case 'Witcher Bear Jacket Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Jacket Upgrade schematic 3');
				return true;
			case 'Witcher Bear Boots Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Boots Upgrade schematic 1');
				return true;
			case 'Witcher Bear Pants Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Pants Upgrade schematic 1');
				return true;
			case 'Witcher Bear Gloves Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Bear Gloves Upgrade schematic 1');
				return true;
			case 'Bear School steel sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Bear School steel sword Upgrade schematic 1');
				return true;
			case 'Bear School steel sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Bear School steel sword Upgrade schematic 2');
				return true;
			case 'Bear School steel sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Bear School steel sword Upgrade schematic 3');
				return true;
			case 'Bear School silver sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Bear School silver sword Upgrade schematic 1');
				return true;
			case 'Bear School silver sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Bear School silver sword Upgrade schematic 2');
				return true;
			case 'Bear School silver sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Bear School silver sword Upgrade schematic 3');
				return true;
				
			case 'Witcher Gryphon Jacket Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Jacket Upgrade schematic 1');
				return true;
			case 'Witcher Gryphon Jacket Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Jacket Upgrade schematic 2');
				return true;
			case 'Witcher Gryphon Jacket Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Jacket Upgrade schematic 3');
				return true;
			case 'Witcher Gryphon Boots Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Boots Upgrade schematic 1');
				return true;
			case 'Witcher Gryphon Pants Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Pants Upgrade schematic 1');
				return true;
			case 'Witcher Gryphon Gloves Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Gryphon Gloves Upgrade schematic 1');
				return true;
			case 'Gryphon School steel sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School steel sword Upgrade schematic 1');
				return true;
			case 'Gryphon School steel sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School steel sword Upgrade schematic 2');
				return true;
			case 'Gryphon School steel sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School steel sword Upgrade schematic 3');
				return true;
			case 'Gryphon School silver sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School silver sword Upgrade schematic 1');
				return true;
			case 'Gryphon School silver sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School silver sword Upgrade schematic 2');
				return true;
			case 'Gryphon School silver sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Gryphon School silver sword Upgrade schematic 3');
				return true;
				
			case 'Witcher Wolf Jacket Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Jacket Upgrade schematic 1');
				return true;
			case 'Witcher Wolf Jacket Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Jacket Upgrade schematic 2');
				return true;
			case 'Witcher Wolf Jacket Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Jacket Upgrade schematic 3');
				return true;
			case 'Witcher Wolf Boots Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Boots Upgrade schematic 1');
				return true;
			case 'Witcher Wolf Pants Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Pants Upgrade schematic 1');
				return true;
			case 'Witcher Wolf Gloves Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Wolf Gloves Upgrade schematic 1');
				return true;
			case 'Wolf School steel sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School steel sword Upgrade schematic 1');
				return true;
			case 'Wolf School steel sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School steel sword Upgrade schematic 2');
				return true;
			case 'Wolf School steel sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School steel sword Upgrade schematic 3');
				return true;
			case 'Wolf School silver sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School silver sword Upgrade schematic 1');
				return true;
			case 'Wolf School silver sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School silver sword Upgrade schematic 2');
				return true;
			case 'Wolf School silver sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Wolf School silver sword Upgrade schematic 3');
				return true;
			
			case 'Witcher Lynx Jacket Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Jacket Upgrade schematic 1');
				return true;
			case 'Witcher Lynx Jacket Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Jacket Upgrade schematic 2');
				return true;
			case 'Witcher Lynx Jacket Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Jacket Upgrade schematic 3');
				return true;
			case 'Witcher Lynx Boots Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Boots Upgrade schematic 1');
				return true;
			case 'Witcher Lynx Pants Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Pants Upgrade schematic 1');
				return true;
			case 'Witcher Lynx Gloves Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Witcher Lynx Gloves Upgrade schematic 1');
				return true;
			case 'Lynx School steel sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School steel sword Upgrade schematic 1');
				return true;
			case 'Lynx School steel sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School steel sword Upgrade schematic 2');
				return true;
			case 'Lynx School steel sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School steel sword Upgrade schematic 3');
				return true;
			case 'Lynx School silver sword Upgrade schematic 1':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School silver sword Upgrade schematic 1');
				return true;
			case 'Lynx School silver sword Upgrade schematic 2':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School silver sword Upgrade schematic 2');
				return true;
			case 'Lynx School silver sword Upgrade schematic 3':
				GetWitcherPlayer().AddCraftingSchematic('Lynx School silver sword Upgrade schematic 3');
				return true;
			
			default:
				return false;
		}
	}
	*/
	
	// ---------------------------------------------------------------------------
	// #Books End
	// ---------------------------------------------------------------------------

	//gets weapon damage types from XML definition
	function GetWeaponDTNames( id : SItemUniqueId, out dmgNames : array< name > ) : int
	{
		var attrs : array< name >;
		var i, size : int;
	
		dmgNames.Clear();
	
		if( IsIdValid(id) )
		{
			GetItemAttributes( id, attrs );
			size = attrs.Size();
			
			for( i = 0; i < size; i += 1 )
				if( IsDamageTypeNameValid(attrs[i]) )
					dmgNames.PushBack( attrs[i] );
			
			if(dmgNames.Size() == 0)
				LogAssert(false, "CInventoryComponent.GetWeaponDTNames: weapon <<" + GetItemName(id) + ">> has no damage types defined!");
		}
		return dmgNames.Size();
	}
	
	public function GetWeapons() : array<SItemUniqueId>
	{
		var ids, ids2 : array<SItemUniqueId>;
	
		ids = GetItemsByCategory('monster_weapon');
		ids2 = GetItemsByTag('Weapon');
		ArrayOfIdsAppend(ids, ids2);
		
		return ids;
	}
	
	public function GetHeldWeapons() : array<SItemUniqueId>
	{
		var i : int;
		var w : array<SItemUniqueId>;
	
		w = GetWeapons();
		
		for(i=w.Size()-1; i>=0; i-=1)
		{
			if(!IsItemHeld(w[i]))
			{
				w.EraseFast( i );
			}
		}
		
		return w;
	}
	
	public function GetCurrentlyHeldSword() : SItemUniqueId
	{
		var i	: int;
		var w	: array<SItemUniqueId>;
		
		w = GetHeldWeapons();
		
		for( i = 0 ; i < w.Size() ; i+=1 )
		{
			if( IsItemSteelSwordUsableByPlayer( w[i] ) || IsItemSilverSwordUsableByPlayer( w[i] ) )
			{
				return w[i];
			}
		}
		
		return GetInvalidUniqueId();		
	}
	
	public function GetCurrentlyHeldSwordEntity( out ent : CItemEntity ) : bool
	{
		var id		: SItemUniqueId;
		
		id = GetCurrentlyHeldSword();
		
		if( IsIdValid( id ) )
		{
			ent = GetItemEntityUnsafe( id );
			
			if( ent )
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		return false;
	}
	
	public function GetHeldWeaponsWithCategory( category : name, out items : array<SItemUniqueId> )
	{
		var i : int;
	
		items = GetItemsByCategory( category );
		
		for ( i = items.Size()-1; i >= 0; i -= 1)
		{
			if ( !IsItemHeld( items[i] ) )
			{
				items.EraseFast( i );
			}
		}
	}
		
	public function GetPotionItemBuffData(id : SItemUniqueId, out type : EEffectType, out customAbilityName : name) : bool
	{
		var size, i : int;
		var arr : array<name>;
	
		if(IsIdValid(id))
		{
			GetItemContainedAbilities( id, arr );
			size = arr.Size();
			
			for( i = 0; i < size; i += 1 )
			{
				if( IsEffectNameValid(arr[i]) )
				{
					EffectNameToType(arr[i], type, customAbilityName);
					return true;
				}
			}
		}
		
		return false;
	}

	/**
		Breaks item into recyclable parts and gives them to hero.
	*/
	public function RecycleItem( id : SItemUniqueId, level : ECraftsmanLevel ) :  array<SItemUniqueId>
	{
		var itemsAdded : array<SItemUniqueId>;
		var currentAdded : array<SItemUniqueId>;
		
		var parts : array<SItemParts>;
		var i : int;
		
		parts = GetItemRecyclingParts( id );
		
		for ( i = 0; i < parts.Size(); i += 1 )
		{
			if ( ECL_Grand_Master == level || ECL_Arch_Master == level )
			{
				currentAdded = AddAnItem( parts[i].itemName, parts[i].quantity );
			}
			else if ( ECL_Master == level && parts[i].quantity > 1 )
			{
				currentAdded = AddAnItem( parts[i].itemName, RandRange( parts[i].quantity, 1 ) );
			}
			else
			{
				currentAdded = AddAnItem( parts[i].itemName, 1 );
			}
			itemsAdded.PushBack(currentAdded[0]);
		}

		RemoveItem(id);
		
		return itemsAdded;
	}
		
	//////////////////////////////////////////////////////////////////////////////////////////
	// Potions
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
		Gets buff names that the given item will give. Checks if item defines attribute with a name the same as some buff name.
		Returns buffs size.
	*/
	public function GetItemBuffs( id : SItemUniqueId, out buffs : array<SEffectInfo>) : int
	{
		var attrs, abs, absFast : array< name >;
		var i, k : int;
		var type : EEffectType;
		var abilityName : name;
		var buff : SEffectInfo;
		var dm : CDefinitionsManagerAccessor;
		
		buffs.Clear();
		
		if( !IsIdValid(id) )
			return 0;
		
		//Potential fast exit. Get amount of all abilities included
		GetItemContainedAbilities(id, absFast);
		if(absFast.Size() == 0)
			return 0;
		
		GetItemAbilities(id, abs);
		dm = theGame.GetDefinitionsManager();
		for(k=0; k<abs.Size(); k+=1)
		{
			dm.GetContainedAbilities(abs[k], attrs);
			buff.applyChance = CalculateAttributeValue(GetItemAbilityAttributeValue(id, 'buff_apply_chance', abs[k])) * ArrayOfNamesCount(abs, abs[k]);
			
			for( i = 0; i < attrs.Size(); i += 1 )
			{
				if( IsEffectNameValid(attrs[i]) )
				{
					EffectNameToType(attrs[i], type, abilityName);
					
					buff.effectType = type;
					buff.effectAbilityName = abilityName;					
					
					buffs.PushBack(buff);
					
					//when we found some buff we remove 1 item from all included abilities array - if it's empty we can quit
					if(absFast.Size() == 1)
						return buffs.Size();
					else
						absFast.EraseFast(0);					
				}
			}
		}
		
		return buffs.Size();
	}	
	
	/*
		Drops intem from the inventory to the ground. Item is placed in a bag.
		If there is a bag nearby, the items are added to that bag
	*/
	public function DropItemInBag( item : SItemUniqueId, quantity : int ) // #B probably not in use
	{
		var entities : array<CGameplayEntity>;
		var i : int;
		var owner : CActor;
		var bag : W3ActorRemains;
		var template : CEntityTemplate;
		var bagtags : array <name>;
		var bagPosition : Vector;
		var tracedPosition, tracedNormal : Vector;
				
		if(ItemHasTag(item, 'NoDrop')) // #B shouldn't be also NoShow here ?
			return;		//fast abort
		
		owner = (CActor)GetEntity();
		FindGameplayEntitiesInRange(entities, owner, 0.5, 100);
		
		for(i=0; i<entities.Size(); i+=1)
		{
			bag = (W3ActorRemains)entities[i];
			
			if(bag)
				break;
		}
		
		//create bag entity if none found near
		if(!bag)
		{
			template = (CEntityTemplate)LoadResource("lootbag");
			bagtags.PushBack('lootbag');
			
			// Do raycast down from player position to check if he's in the air
			bagPosition = owner.GetWorldPosition();
			if ( theGame.GetWorld().StaticTrace( bagPosition, bagPosition + Vector( 0.0f, 0.0f, -10.0f, 0.0f ), tracedPosition, tracedNormal ) )
			{
				bagPosition = tracedPosition;
			}
			bag = (W3ActorRemains)theGame.CreateEntity(template, bagPosition, owner.GetWorldRotation(), true, false, false, PM_Persist,bagtags);
		}
	
		//give item
		GiveItemTo(bag.GetInventory(), item, quantity, false);
		
		//if item was not given for some reason then delete empty bag
		if(bag.GetInventory().IsEmpty())
		{
			delete bag;
			return;
		}		
		//if item added successfully
		bag.LootDropped();		//this will also reset the timer if we add items to an already created container
		theTelemetry.LogWithLabelAndValue(TE_INV_ITEM_DROPPED, GetItemName(item), quantity);
		
		// if dropped underwater, play curve animation of "floating"
		if( thePlayer.IsSwimming() )
		{
			bag.PlayPropertyAnimation( 'float', 0 );
		}
	}
	
	/////////////////////////////////////////////
	//         @REPAIR OBJECTS
	/////////////////////////////////////////////
	
	//returns true if some bonus was added
	public final function AddRepairObjectItemBonuses(buffArmor : bool, buffSwords : bool, ammoArmor : int, ammoWeapon : int) : bool
	{
		var upgradedSomething, isArmor : bool;
		var i, ammo, currAmmo : int;
		var items, items2 : array<SItemUniqueId>;
		
		//get items to upgrade
		if(buffArmor)
		{
			items = GetItemsByTag(theGame.params.TAG_ARMOR);
		}
		if(buffSwords)
		{
			items2 = GetItemsByTag(theGame.params.TAG_PLAYER_STEELSWORD);
			ArrayOfIdsAppend(items, items2);
			items2.Clear();
			items2 = GetItemsByTag(theGame.params.TAG_PLAYER_SILVERSWORD);
			ArrayOfIdsAppend(items, items2);
		}
		
		upgradedSomething = false;
		
		for(i=0; i<items.Size(); i+=1)
		{
			//check if item is armor
			if(IsItemAnyArmor(items[i]))
			{
				isArmor = true;
				ammo = ammoArmor;
			}
			else
			{
				isArmor = false;
				ammo = ammoWeapon;
			}
			
			//get current ammo
			currAmmo = GetItemModifierInt(items[i], 'repairObjectBonusAmmo', 0);
			
			//if ammo is greater than current
			if(ammo > currAmmo)
			{
				SetItemModifierInt(items[i], 'repairObjectBonusAmmo', ammo);
				upgradedSomething = true;
				
				//if had no ammo - add ability
				if(currAmmo == 0)
				{
					if(isArmor)
						AddItemCraftedAbility(items[i], theGame.params.REPAIR_OBJECT_BONUS_ARMOR_ABILITY, false);
					else
						AddItemCraftedAbility(items[i], theGame.params.REPAIR_OBJECT_BONUS_WEAPON_ABILITY, false);
				}
			}
		}
		
		return upgradedSomething;
	}
	
	public final function ReduceItemRepairObjectBonusCharge(item : SItemUniqueId)	
	{
		var currAmmo : int;
		
		currAmmo = GetItemModifierInt(item, 'repairObjectBonusAmmo', 0);
		
		if(currAmmo > 0)
		{
			SetItemModifierInt(item, 'repairObjectBonusAmmo', currAmmo - 1);
		
			if(currAmmo == 1)
			{
				if(IsItemAnyArmor(item))
					RemoveItemCraftedAbility(item, theGame.params.REPAIR_OBJECT_BONUS_ARMOR_ABILITY);
				else
					RemoveItemCraftedAbility(item, theGame.params.REPAIR_OBJECT_BONUS_WEAPON_ABILITY);
			}
		}
	}
	
	//gets value of 'armor' attribute bonus for given item from 'repair objects'
	public final function GetRepairObjectBonusValueForArmor(armor : SItemUniqueId) : SAbilityAttributeValue
	{
		var retVal, bonusValue, baseArmor : SAbilityAttributeValue;
		
		if(GetItemModifierInt(armor, 'repairObjectBonusAmmo', 0) > 0)
		{
			bonusValue = GetItemAttributeValue(armor, theGame.params.REPAIR_OBJECT_BONUS);		
			baseArmor = GetItemAttributeValue(armor, theGame.params.ARMOR_VALUE_NAME);
			
			baseArmor.valueMultiplicative += 1;		//added from character ability later on I guess?
			retVal.valueAdditive = bonusValue.valueAdditive + CalculateAttributeValue(baseArmor) * bonusValue.valueMultiplicative;
		}
		
		return retVal;
	}
	
	/////////////////////////////////////////////
	//         @OILS
	/////////////////////////////////////////////
	
	/**
		Checks if item can be upgraded with oil
	*/	
	public function CanItemHaveOil(id : SItemUniqueId) : bool
	{
		return IsItemSteelSwordUsableByPlayer(id) || IsItemSilverSwordUsableByPlayer(id);
	}
	
	public final function RemoveAllOilsFromItem( id : SItemUniqueId )
	{
		var i : int;
		var oils : array< W3Effect_Oil >;
		var actor : CActor;
		
		actor = ( CActor ) GetEntity();
		oils = GetOilsAppliedOnItem( id );
		for( i = oils.Size() - 1; i >= 0; i -= 1 )
		{
			actor.RemoveEffect( oils[ i ] );
		}
	}
	
	public final function GetActiveOilsAppliedOnItemCount( id : SItemUniqueId ) : int
	{
		var oils : array< W3Effect_Oil >;
		var i, count : int;
		
		count = 0;
		oils = GetOilsAppliedOnItem( id );
		for( i=0; i<oils.Size(); i+=1 )
		{
			if( oils[ i ].GetAmmoCurrentCount() > 0 )
			{
				count += 1;
			}
		}
		return count;
	}
	
	public final function RemoveOldestOilFromItem( id : SItemUniqueId )
	{
		var buffToRemove : W3Effect_Oil;
		var actor : CActor;
		
		actor = ( CActor ) GetEntity();
		if(! actor )
			return;
			
		buffToRemove = GetOldestOilAppliedOnItem(id, false);
		
		if(buffToRemove)
		{
			actor.RemoveEffect( buffToRemove );
		}
	}
	
	public final function GetOilsAppliedOnItem( id : SItemUniqueId ) : array< W3Effect_Oil >
	{
		var i : int;
		var oils : array< CBaseGameplayEffect >;
		var buff : W3Effect_Oil;
		var ret : array < W3Effect_Oil >;
		var actor : CActor;
		
		actor = ( CActor ) GetEntity();
		if(! actor )
			return ret;
			
		oils = actor.GetBuffs( EET_Oil );
		for( i = oils.Size() - 1; i >= 0; i -= 1 )
		{
			buff = ( W3Effect_Oil ) oils[ i ];
			if(buff && buff.GetSwordItemId() == id )
			{
				ret.PushBack( buff );
			}
		}
		
		return ret;
	}
	
	public final function GetNewestOilAppliedOnItem( id : SItemUniqueId, onlyShowable : bool ) : W3Effect_Oil
	{
		return GetOilAppliedOnItemInternal( id, onlyShowable, true );
	}
	
	public final function GetOldestOilAppliedOnItem( id : SItemUniqueId, onlyShowable : bool ) : W3Effect_Oil
	{
		return GetOilAppliedOnItemInternal( id, onlyShowable, false );
	}
	
	private final function GetOilAppliedOnItemInternal( id : SItemUniqueId, onlyShowable : bool, newest : bool ) : W3Effect_Oil
	{
		var oils : array< W3Effect_Oil >;
		var i, lastIndex : int;
		
		oils = GetOilsAppliedOnItem( id );
		lastIndex = -1;
		
		for( i=0; i<oils.Size(); i+=1 )
		{
			if( onlyShowable && !oils[i].GetShowOnHUD() )
			{
				continue;
			}
			
			if( lastIndex == -1 )
			{
				lastIndex = i;
			}
			else if( newest && oils[i].GetQueueTimer() < oils[lastIndex].GetQueueTimer() )
			{
				lastIndex = i;
			}
			else if( !newest && oils[i].GetQueueTimer() > oils[lastIndex].GetQueueTimer() )
			{
				lastIndex = i;
			}
		}
		
		if( lastIndex == -1 )
		{
			return NULL;
		}
		
		return oils[lastIndex];
	}
	
	public final function ItemHasAnyActiveOilApplied( id : SItemUniqueId ) : bool
	{
		return GetActiveOilsAppliedOnItemCount( id );
	}
	
	public final function ItemHasActiveOilApplied( id : SItemUniqueId, monsterCategory : EMonsterCategory ) : bool
	{
		var i : int;
		var oils : array< W3Effect_Oil >;
		
		oils = GetOilsAppliedOnItem( id );
		for( i=0; i<oils.Size(); i+=1 )
		{
			if( oils[ i ].GetMonsterCategory() == monsterCategory && oils[ i ].GetAmmoCurrentCount() > 0 )
			{
				return true;
			}
		}
		
		return false;
	}
	
	/////////////////////////////////////////////
	//         TOOLTIPS
	/////////////////////////////////////////////
	
	public final function GetParamsForRunewordTooltip(runewordName : name, out i : array<int>, out f : array<float>, out s : array<string>)
	{
		var min, max : SAbilityAttributeValue;
		var val : float;
		var attackRangeBase, attackRangeExt : CAIAttackRange;
		
		i.Clear();
		f.Clear();
		s.Clear();
		
		switch(runewordName)
		{
			case 'Glyphword 5':
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 5 _Stats', 'glyphword5_chance', min, max);				
				i.PushBack( RoundMath( CalculateAttributeValue(min) * 100) );
				break;
			case 'Glyphword 6' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 6 _Stats', 'glyphword6_stamina_drain_perc', min, max);				
				i.PushBack( RoundMath( CalculateAttributeValue(min) * 100) );
				break;
			case 'Glyphword 12' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 12 _Stats', 'glyphword12_range', min, max);
				val = CalculateAttributeValue(min);
				s.PushBack( NoTrailZeros(val) );
				
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 12 _Stats', 'glyphword12_chance', min, max);
				i.PushBack( RoundMath( min.valueAdditive * 100) );
				break;
			case 'Glyphword 17' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 17 _Stats', 'quen_apply_chance', min, max);
				val = CalculateAttributeValue(min);
				i.PushBack( RoundMath(val * 100) );
				break;
			case 'Glyphword 14' :
			case 'Glyphword 18' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Glyphword 18 _Stats', 'increas_duration', min, max);
				val = CalculateAttributeValue(min);
				s.PushBack( NoTrailZeros(val) );
				break;
				
			case 'Runeword 2' :
				attackRangeBase = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'specialattacklight');
				attackRangeExt = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'runeword2_light');				
				s.PushBack( NoTrailZeros(attackRangeExt.rangeMax - attackRangeBase.rangeMax) );
				
				attackRangeBase = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'slash_long');
				attackRangeExt = theGame.GetAttackRangeForEntity(GetWitcherPlayer(), 'runeword2_heavy');				
				s.PushBack( NoTrailZeros(attackRangeExt.rangeMax - attackRangeBase.rangeMax) );
				
				break;
			case 'Runeword 4' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue('Runeword 4 _Stats', 'max_bonus', min, max);
				i.PushBack( RoundMath(max.valueMultiplicative * 100) );	//hardcoded
				break;
			case 'Runeword 6' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 6 _Stats', 'runeword6_duration_bonus', min, max );
				i.PushBack( RoundMath(min.valueMultiplicative * 100) );
				break;
			case 'Runeword 7' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 7 _Stats', 'stamina', min, max );
				i.PushBack( RoundMath(min.valueMultiplicative * 100) );
				break;
			case 'Runeword 10' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 10 _Stats', 'stamina', min, max );
				i.PushBack( RoundMath(min.valueMultiplicative * 100) );	//hardcoded
				break;
			case 'Runeword 11' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 11 _Stats', 'duration', min, max );
				s.PushBack( NoTrailZeros(min.valueAdditive) );
				break;
			case 'Runeword 12' :
				theGame.GetDefinitionsManager().GetAbilityAttributeValue( 'Runeword 12 _Stats', 'focus', min, max );
				f.PushBack(min.valueAdditive);
				f.PushBack(max.valueAdditive);
				break;
			default:
				break;
		}
	}
	
	public final function GetPotionAttributesForTooltip(potionId : SItemUniqueId, out tips : array<SAttributeTooltip>):void
	{
		var i, j, settingsSize : int;
		var buffType : EEffectType;
		var abilityName : name;
		var abs, attrs : array<name>;
		var val : SAbilityAttributeValue;
		var newAttr : SAttributeTooltip;
		var attributeString : string;
		
		//if not a potion then quit
		if(!IsItemPotion(potionId))
			return;
			
		//get potion buff attributes
		GetItemContainedAbilities(potionId, abs);
		for(i=0; i<abs.Size(); i+=1)
		{
			EffectNameToType(abs[i], buffType, abilityName);
			
			//not a buff ability
			if(buffType == EET_Undefined)
				continue;
				
			//otherwise get list of attributes
			theGame.GetDefinitionsManager().GetAbilityAttributes(abs[i], attrs);
			break;
		}
		
		//custom attribute filtering
		attrs.Remove('duration');
		attrs.Remove('level');
		
		if(buffType == EET_Cat)
		{
			//internal
			attrs.Remove('highlightObjectsRange');
		}
		else if(buffType == EET_GoldenOriole)
		{
			//in tooltip
			attrs.Remove('poison_resistance_perc');
		}
		else if(buffType == EET_MariborForest)
		{
			//in tooltip
			attrs.Remove('focus_on_drink');
		}
		else if(buffType == EET_KillerWhale)
		{
			//internal
			attrs.Remove('swimmingStamina');
			attrs.Remove('vision_strength');
		}
		else if(buffType == EET_Thunderbolt)
		{
			//in tooltip
			attrs.Remove('critical_hit_chance');
		}
		else if(buffType == EET_WhiteRaffardDecoction)
		{
			val = GetItemAttributeValue(potionId, 'level');
			if(val.valueAdditive == 3)
				attrs.Insert(0, 'duration');
		}
		else if(buffType == EET_Mutagen20)
		{
			attrs.Remove('burning_DoT_damage_resistance_perc');
			attrs.Remove('poison_DoT_damage_resistance_perc');
			attrs.Remove('bleeding_DoT_damage_resistance_perc');
		}
		else if(buffType == EET_Mutagen27)
		{
			attrs.Remove('mutagen27_max_stack');
		}
		else if(buffType == EET_Mutagen18)
		{
			attrs.Remove('mutagen18_max_stack');
		}
		else if(buffType == EET_Mutagen19)
		{
			attrs.Remove('max_hp_perc_trigger');
		}
		else if(buffType == EET_Mutagen21)
		{
			attrs.Remove('healingRatio');
		}
		else if(buffType == EET_Mutagen22)
		{
			attrs.Remove('mutagen22_max_stack');
		}
		else if(buffType == EET_Mutagen02)
		{
			attrs.Remove('resistGainRate');
		}
		else if(buffType == EET_Mutagen04)
		{
			attrs.Remove('staminaCostPerc');
			attrs.Remove('healthReductionPerc');
		}
		else if(buffType == EET_Mutagen08)
		{
			attrs.Remove('resistGainRate');
		}
		else if(buffType == EET_Mutagen10)
		{
			attrs.Remove('mutagen10_max_stack');
		}
		else if(buffType == EET_Mutagen14)
		{
			attrs.Remove('mutagen14_max_stack');
		}
		
		//fill attribute names and values
		for(j=0; j<attrs.Size(); j+=1)
		{
			val = GetItemAbilityAttributeValue(potionId, attrs[j], abs[i]);
			
			newAttr.originName = attrs[j];
			newAttr.attributeName = GetAttributeNameLocStr(attrs[j], false);
			
			if(buffType == EET_MariborForest && attrs[j] == 'focus_gain')
			{
				newAttr.value = val.valueAdditive;
				newAttr.percentageValue = false;
			}
			else if(val.valueMultiplicative != 0)
			{
				if(buffType == EET_Mutagen26)
				{
					//uses same attribute twice with mult and add
					newAttr.value = val.valueAdditive;
					newAttr.percentageValue = false;
					tips.PushBack(newAttr);
					
					newAttr.value = val.valueMultiplicative;
					newAttr.percentageValue = true;
					
					attrs.Erase(1);					
				}
				else if(buffType == EET_Mutagen07)
				{
					//has mult == 1 and uses base
					attrs.Erase(1);
					newAttr.value = val.valueBase;
					newAttr.percentageValue = true;
				}
				else
				{
					newAttr.value = val.valueMultiplicative;
					newAttr.percentageValue = true;
				}
			}
			else if(val.valueAdditive != 0)
			{
				if(buffType == EET_Thunderbolt)
				{
					newAttr.value = val.valueAdditive * 100;
					newAttr.percentageValue = true;
				}
				else if(buffType == EET_Blizzard)
				{
					newAttr.value = 1 - val.valueAdditive;
					newAttr.percentageValue = true;
				}
				else if(buffType == EET_Mutagen01 || buffType == EET_Mutagen15 || buffType == EET_Mutagen28 || buffType == EET_Mutagen27)
				{
					newAttr.value = val.valueAdditive;
					newAttr.percentageValue = true;
				}
				else
				{
					newAttr.value = val.valueAdditive;
					newAttr.percentageValue = false;
				}
			}
			else if(buffType == EET_GoldenOriole)
			{
				newAttr.value = val.valueBase;
				newAttr.percentageValue = true;
			}
			else
			{
				newAttr.value = val.valueBase;
				newAttr.percentageValue = false;
			}
			
			tips.PushBack(newAttr);
		}
	}
	
	/**	
		ACHTUNG!
	
		This cannot be done by taking two ids of items because the id is unique ONLY in THIS inventory. 
		So if you have items from two different inventories (like shop, container) the id of the item from
		the other inventory cannot be used in this inventory (it will point to NULL or some other random item).
		
		id - item id of the item in this inventory		
		invOther - inventory component of the other item
		idOther - item id of the other item
	*/
	public function GetItemRelativeTooltipType(id :SItemUniqueId, invOther : CInventoryComponent, idOther : SItemUniqueId) : ECompareType
	{	
		
		if( (GetItemCategory(id) == invOther.GetItemCategory(idOther)) ||
		    ItemHasTag(id, 'PlayerSteelWeapon') && invOther.ItemHasTag(idOther, 'PlayerSteelWeapon') ||
		    ItemHasTag(id, 'PlayerSilverWeapon') && invOther.ItemHasTag(idOther, 'PlayerSilverWeapon') ||
		    ItemHasTag(id, 'PlayerSecondaryWeapon') && invOther.ItemHasTag(idOther, 'PlayerSecondaryWeapon')
		)
		{
			return ECT_Compare;
		}
		return ECT_Incomparable;
	}
	
	/**
		Formats a float value to show in the tooltip. The value is decimal with 2 points after the dot always. // #B deprecated
	*/
	private function FormatFloatForTooltip(fValue : float) : string
	{
		var valueInt, valueDec : int;
		var strValue : string;
		
		if(fValue < 0)
		{
			valueInt = CeilF(fValue);
			valueDec = RoundMath((fValue - valueInt)*(-100));
		}
		else
		{
			valueInt = FloorF(fValue);
			valueDec = RoundMath((fValue - valueInt)*(100));
		}
		strValue = valueInt+".";
		if(valueDec < 10)
			strValue += "0"+valueDec;
		else
			strValue += ""+valueDec;
		
		return strValue;
	}

	public function SetPriceMultiplier( mult : float )
	{
		priceMult = mult;
	}
	
	// Price modified by area and item category
	public function GetMerchantPriceModifier( shopNPC : CNewNPC, item : SItemUniqueId ) : float
	{
		var areaPriceMult		: float;
		var itemPriceMult		: float;
		var importPriceMult		: float;
		var finalPriceMult		: float;
		var tag					: name;
		var zoneName			: EZoneName;
		
		zoneName = theGame.GetCurrentZone();
		
		switch ( zoneName )
		{
			case ZN_NML_CrowPerch 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('crow_perch_price_mult'));
			case ZN_NML_SpitfireBluff 		: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('spitfire_bluff_price_mult'));
			case ZN_NML_TheMire 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('the_mire_price_mult'));
			case ZN_NML_Mudplough 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('mudplough_price_mult'));
			case ZN_NML_Grayrocks 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('grayrocks_price_mult'));
			case ZN_NML_TheDescent 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('the_descent_price_mult'));
			case ZN_NML_CrookbackBog 		: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('crookback_bog_price_mult'));
			case ZN_NML_BaldMountain 		: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('bald_mountain_price_mult'));
			case ZN_NML_Novigrad 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('novigrad_price_mult'));
			case ZN_NML_Homestead 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('homestead_price_mult'));
			case ZN_NML_Gustfields 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('gustfields_price_mult'));
			case ZN_NML_Oxenfurt 			: areaPriceMult = CalculateAttributeValue(thePlayer.GetAttributeValue('oxenfurt_price_mult'));
			case ZN_Undefined				: areaPriceMult = 1;
		}
		
		if 		(ItemHasTag(item,'weapon')) 	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('weapon_price_mult')); }
		else if (ItemHasTag(item,'armor')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('armor_price_mult')); }
		else if (ItemHasTag(item,'crafting')) 	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('crafting_price_mult')); }
		else if (ItemHasTag(item,'alchemy')) 	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('alchemy_price_mult')); }
		else if (ItemHasTag(item,'alcohol')) 	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('alcohol_price_mult')); }
		else if (ItemHasTag(item,'food')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('food_price_mult')); }
		else if (ItemHasTag(item,'fish')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('fish_price_mult')); }
		else if (ItemHasTag(item,'books')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('books_price_mult')); }
		else if (ItemHasTag(item,'valuables'))	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('valuables_price_mult')); }
		else if (ItemHasTag(item,'junk')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('junk_price_mult')); }
		else if (ItemHasTag(item,'orens')) 		{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('orens_price_mult')); }
		else if (ItemHasTag(item,'florens')) 	{ itemPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('florens_price_mult')); }
		else { itemPriceMult = 1; }
		
		if 		(ItemHasTag(item,'novigrad')) 	{ importPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('novigrad_price_mult')); }
		else if (ItemHasTag(item,'nilfgard')) 	{ importPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('nilfgard_price_mult')); }
		else if (ItemHasTag(item,'nomansland'))	{ importPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('nomansland_price_mult')); }
		else if (ItemHasTag(item,'skellige')) 	{ importPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('skellige_price_mult')); }
		else if (ItemHasTag(item,'nonhuman')) 	{ importPriceMult = CalculateAttributeValue(shopNPC.GetAttributeValue('nonhuman_price_mult')); }
		else { importPriceMult = 1; }
		
		finalPriceMult = areaPriceMult*itemPriceMult*importPriceMult*priceMult;
		return  finalPriceMult;
	}	

	public function SetRepairPriceMultiplier( mult : float ) // #B
	{
		priceRepairMult = mult;
	}
	
	// Price modified by area and item category
	public function GetRepairPriceModifier( repairNPC : CNewNPC ) : float // #B should be taken from NPC invComp
	{
		return priceRepairMult;
	}	
	
	public function GetRepairPrice( item : SItemUniqueId ) : float // #B
	{
		var currDiff : float;
		currDiff = GetItemMaxDurability(item) - GetItemDurability(item); 
		
		return priceRepair * currDiff;
	}
	
	//fills item tooltip data
	public function GetTooltipData(itemId : SItemUniqueId, out localizedName : string, out localizedDescription : string, out price : int, out localizedCategory : string,
									out itemStats : array<SAttributeTooltip>, out localizedFluff : string)
	{
		if( !IsIdValid(itemId) )
		{
			return;
		}
		localizedName = GetItemLocalizedNameByUniqueID(itemId);
		localizedDescription = GetItemLocalizedDescriptionByUniqueID(itemId);
		localizedFluff = "IMPLEMENT ME - fluff text";
		price = GetItemPriceModified( itemId, false );
		localizedCategory = GetItemCategoryLocalisedString(GetItemCategory(itemId));
		GetItemStats(itemId, itemStats);
	}
	
	// get only item's base and crafted stats
	public function GetItemBaseStats(itemId : SItemUniqueId, out itemStats : array<SAttributeTooltip>)
	{
		var attributes : array<name>;
		
		var dm	: CDefinitionsManagerAccessor;
		var oilAbilities, oilAttributes : array<name>;
		var weights : array<float>;
		var i, j : int;
		var tmpI, tmpJ : int;
		
		var idx			  : int;
		var oilStatsCount : int;
		var oilName  	  : name;
		var oilStats 	  : array<SAttributeTooltip>;
		var oilStatFirst  : SAttributeTooltip;
		var oils		  : array< W3Effect_Oil >;
		
		GetItemBaseAttributes(itemId, attributes);
		
		// #Y hack to remove oil bufs from this list		
		oils = GetOilsAppliedOnItem( itemId );
		dm = theGame.GetDefinitionsManager();
		for( i=0; i<oils.Size(); i+=1 )
		{
			oilName = oils[ i ].GetOilItemName();
			
			oilAbilities.Clear();
			weights.Clear();
			dm.GetItemAbilitiesWithWeights(oilName, GetEntity() == thePlayer, oilAbilities, weights, tmpI, tmpJ);
			
			oilAttributes.Clear();
			oilAttributes = dm.GetAbilitiesAttributes(oilAbilities);
			
			oilStatsCount = oilAttributes.Size();
			for (idx = 0; idx < oilStatsCount; idx+=1)
			{
				attributes.Remove(oilAttributes[idx]);
			}
		}
		
		GetItemTooltipAttributes(itemId, attributes, itemStats);
	}
	
	//filling attributes/statsfluff
	public function GetItemStats(itemId : SItemUniqueId, out itemStats : array<SAttributeTooltip>)
	{
		var attributes : array<name>;
		
		GetItemAttributes(itemId, attributes);
		GetItemTooltipAttributes(itemId, attributes, itemStats);
	}
	
	private function GetItemTooltipAttributes(itemId : SItemUniqueId, attributes : array<name>, out itemStats : array<SAttributeTooltip>):void
	{
		var itemCategory:name;
		var i, j, settingsSize : int;
		var attributeString : string;
		var attributeColor : string;
		var attributeName : name;
		var isPercentageValue : string;
		var primaryStatLabel : string;
		var statLabel		 : string;
		
		var stat : SAttributeTooltip;
		var attributeVal : SAbilityAttributeValue;
		
		settingsSize = theGame.tooltipSettings.GetNumRows();
		itemStats.Clear();
		itemCategory = GetItemCategory(itemId);
		for(i=0; i<settingsSize; i+=1)
		{
			//get next in order attribute name
			attributeString = theGame.tooltipSettings.GetValueAt(0,i);
			if(StrLen(attributeString) <= 0)
				continue;						//just an empty line in file
			
			attributeName = '';
			
			//check if this item has this attribute
			for(j=0; j<attributes.Size(); j+=1)
			{
				if(NameToString(attributes[j]) == attributeString)
				{
					attributeName = attributes[j];
					break;
				}
			}
			if(!IsNameValid(attributeName))
				continue;
			
			// hardcode: we don't show damage for swords
			if(itemCategory == 'silversword' && attributeName == 'SlashingDamage') continue;
			if(itemCategory == 'steelsword' && attributeName == 'SilverDamage') continue;
			
			//get the color of the attribute string (for the tooltip panel)
			attributeColor = theGame.tooltipSettings.GetValueAt(1,i);
			
			isPercentageValue = theGame.tooltipSettings.GetValueAt(2,i);	
			
			//if yes then get the values and add them to stats array
			attributeVal = GetItemAttributeValue(itemId, attributeName);
			stat.attributeColor = attributeColor;
			stat.percentageValue = isPercentageValue;			
			stat.primaryStat = IsPrimaryStatById(itemId, attributeName, primaryStatLabel);
			stat.value = 0;
			stat.originName = attributeName;
			if(attributeVal.valueBase != 0)
			{
				statLabel = GetAttributeNameLocStr(attributeName, false);
				stat.value = attributeVal.valueBase;
			}
			if(attributeVal.valueMultiplicative != 0)
			{				
				// #J setting percentage Value to true is smarter here and the localized version of the _mult strings doesn't exist and is overkill from what I can tell
				// So changing true to false
				statLabel = GetAttributeNameLocStr(attributeName, false);
				stat.value = attributeVal.valueMultiplicative;
				stat.percentageValue = true;
			}
			if(attributeVal.valueAdditive != 0)
			{				
				statLabel = GetAttributeNameLocStr(attributeName, false);
				stat.value = attributeVal.valueAdditive;
			}
			if (stat.value != 0)
			{
				stat.attributeName = statLabel;
				//stat.attributeName = primaryStatLabel;
				itemStats.PushBack(stat);
			}
		}
	}
	
	//filling attributes/statsfluff for crafting recipe
	public function GetItemStatsFromName(itemName : name, out itemStats : array<SAttributeTooltip>)
	{
		var itemCategory : name;
		var i, j, settingsSize : int;
		var attributeString : string;
		var attributeColor : string;
		var attributeName : name;
		var isPercentageValue : string;
		var attributes, itemAbilities, tmpArray : array<name>;
		var weights : array<float>;
		var stat : SAttributeTooltip;
		var attributeVal, min, max : SAbilityAttributeValue;
		var dm	: CDefinitionsManagerAccessor;
		var primaryStatLabel : string;
		var statLabel		 : string;
		
		settingsSize = theGame.tooltipSettings.GetNumRows();
		dm = theGame.GetDefinitionsManager();
		dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, itemAbilities, weights, i, j);
		attributes = dm.GetAbilitiesAttributes(itemAbilities);
		
		itemStats.Clear();
		itemCategory = dm.GetItemCategory(itemName);
		for(i=0; i<settingsSize; i+=1)
		{
			//get next in order attribute name
			attributeString = theGame.tooltipSettings.GetValueAt(0,i);
			if(StrLen(attributeString) <= 0)
				continue;						//just an empty line in file
			
			attributeName = '';
			
			//check if this item has this attribute
			for(j=0; j<attributes.Size(); j+=1)
			{
				if(NameToString(attributes[j]) == attributeString)
				{
					attributeName = attributes[j];
					break;
				}
			}
			if(!IsNameValid(attributeName))
				continue;
			
			// hardcode: we don't show damage for swords
			if(itemCategory == 'silversword' && attributeName == 'SlashingDamage') continue;
			if(itemCategory == 'steelsword' && attributeName == 'SilverDamage') continue;
			
			//get the color of the attribute string (for the tooltip panel)
			attributeColor = theGame.tooltipSettings.GetValueAt(1,i);
			
			isPercentageValue = theGame.tooltipSettings.GetValueAt(2,i);
			
			//if yes then get the values and add them to stats array
			dm.GetAbilitiesAttributeValue(itemAbilities, attributeName, min, max);
			attributeVal = GetAttributeRandomizedValue(min, max);
			//attributeVal = GetItemAttributeValue(itemId, attributeName);
			stat.attributeColor = attributeColor;
			stat.percentageValue = isPercentageValue;
			
			stat.primaryStat = IsPrimaryStat(itemCategory, attributeName, primaryStatLabel);
			
			stat.value = 0;
			stat.originName = attributeName;
			
			if(attributeVal.valueBase != 0)
			{
				stat.value = attributeVal.valueBase;
			}
			if(attributeVal.valueMultiplicative != 0)
			{
				stat.value = attributeVal.valueMultiplicative;
				stat.percentageValue = true;
			}
			if(attributeVal.valueAdditive != 0)
			{				
				statLabel = GetAttributeNameLocStr(attributeName, false);
				stat.value = attributeVal.valueBase + attributeVal.valueAdditive;
			}
			
			if (attributeName == 'toxicity_offset')
			{
				statLabel = GetAttributeNameLocStr('toxicity', false);
				stat.percentageValue = false;
			}
			else
			{
				statLabel = GetAttributeNameLocStr(attributeName, false);
			}
			
			if (stat.value != 0)
			{
				stat.attributeName = statLabel;
				//stat.attributeName = primaryStatLabel;
				itemStats.PushBack(stat);
			}
			
			//itemStats.PushBack(stat);
		}
	}
	
	public function IsThereItemOnSlot(slot : EEquipmentSlots) : bool
	{
		var player : W3PlayerWitcher;
			
		player = ((W3PlayerWitcher)GetEntity());
		if(player)
		{		
			return player.IsAnyItemEquippedOnSlot(slot);
		}
		else
		{
			return false;
		}
	}
	
	public function GetItemEquippedOnSlot(slot : EEquipmentSlots, out item : SItemUniqueId) : bool
	{
		var player : W3PlayerWitcher;
			
		player = ((W3PlayerWitcher)GetEntity());
		if(player)
		{
			return player.GetItemEquippedOnSlot(slot, item);
		}
		else
		{
			return false;
		}
	}
	
	public function IsItemExcluded ( itemID : SItemUniqueId, excludedItems : array < SItemNameProperty > ) : bool
	{
		var i 				: int;
		var currItemName 	: name;
		
		currItemName = GetItemName( itemID );
		
		for ( i = 0; i < excludedItems.Size(); i+=1 )
		{
			if ( currItemName == excludedItems[i].itemName )
			{
				return true;
			}
		}
		return false;
	}
	
	// #Y TODO: Check it
	public function GetItemPrimaryStat(itemId : SItemUniqueId, out attributeLabel : string, out attributeVal : float ) : void
	{
		var attributeName : name;
		var attributeValue:SAbilityAttributeValue;
		
		GetItemPrimaryStatImplById(itemId, attributeLabel, attributeVal, attributeName);
		
		attributeValue = GetItemAttributeValue(itemId, attributeName);
		
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
	}
	
	public function GetItemStatByName(itemName : name, statName : name, out resultValue : float) : void
	{
		var dm : CDefinitionsManagerAccessor;
		var attributes, itemAbilities : array<name>;
		var min, max, attributeValue : SAbilityAttributeValue;
		var tmpInt : int;
		var tmpArray : array<float>;
		
		dm = theGame.GetDefinitionsManager();
		dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, itemAbilities, tmpArray, tmpInt, tmpInt);
		attributes = dm.GetAbilitiesAttributes(itemAbilities);
		
		dm.GetAbilitiesAttributeValue(itemAbilities, statName, min, max);
		attributeValue = GetAttributeRandomizedValue(min, max);
		
		if(attributeValue.valueBase != 0)
		{
			resultValue = attributeValue.valueBase;
		}
		if(attributeValue.valueMultiplicative != 0)
		{								
			resultValue = attributeValue.valueMultiplicative;
		}
		if(attributeValue.valueAdditive != 0)
		{
			resultValue = attributeValue.valueAdditive;
		}
	}
	
	public function GetItemPrimaryStatFromName(itemName : name,  out attributeLabel : string, out attributeVal : float, out primAttrName : name) : void
	{
		var dm : CDefinitionsManagerAccessor;
		var attributeName : name;
		var attributes, itemAbilities : array<name>;
		var attributeValue, min, max : SAbilityAttributeValue;
		
		var tmpInt : int;
		var tmpArray : array<float>;
		
		dm = theGame.GetDefinitionsManager();
		
		GetItemPrimaryStatImpl(dm.GetItemCategory(itemName), attributeLabel, attributeVal, attributeName);
		dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, itemAbilities, tmpArray, tmpInt, tmpInt);
		attributes = dm.GetAbilitiesAttributes(itemAbilities);
		for (tmpInt = 0; tmpInt < attributes.Size(); tmpInt += 1)
			if (attributes[tmpInt] == attributeName)
			{
				dm.GetAbilitiesAttributeValue(itemAbilities, attributeName, min, max);
				attributeValue = GetAttributeRandomizedValue(min, max);
				primAttrName = attributeName;
				break;
			}
			
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
		
	}
	
	public function IsPrimaryStatById(itemId : SItemUniqueId, attributeName : name, out attributeLabel : string) : bool
	{
		var attrValue : float;
		var attrName  : name;
		
		GetItemPrimaryStatImplById(itemId, attributeLabel, attrValue, attrName);
		return attrName == attributeName;
	}
	
	private function GetItemPrimaryStatImplById(itemId : SItemUniqueId, out attributeLabel : string, out attributeVal : float, out attributeName : name ) : void
	{
		var itemOnSlot   : SItemUniqueId;
		var categoryName : name;
		var abList   	 : array<name>;
		
		attributeName = '';
		attributeLabel = "";
		categoryName = GetItemCategory(itemId);
		
		// #Y Maybe we can just select max stat? TODO: Discuss with Kanik
		if (categoryName == 'bolt' || categoryName == 'petard')
		{
			GetItemAttributes(itemId, abList);
			if (abList.Contains('FireDamage'))
			{
				attributeName = 'FireDamage';
			}
			else if (abList.Contains('PiercingDamage'))
			{
				attributeName = 'PiercingDamage';
			}
			else if (abList.Contains('PiercingDamage'))
			{
				attributeName = 'PiercingDamage';
			}
			else if (abList.Contains('PoisonDamage'))
			{
				attributeName = 'PoisonDamage';
			}
			else if (abList.Contains('BludgeoningDamage'))
			{
				attributeName = 'BludgeoningDamage';
			}
			else			
			{
				attributeName = 'PhysicalDamage';
			}
			attributeLabel = GetAttributeNameLocStr(attributeName, false);
		}
		else if (categoryName == 'secondary')
		{
			GetItemAttributes(itemId, abList);
			if (abList.Contains('BludgeoningDamage'))
			{
				attributeName = 'BludgeoningDamage';
			}
			else
			{
				attributeName = 'PhysicalDamage';
			}
			attributeLabel = GetAttributeNameLocStr(attributeName, false);
		}
		else if (categoryName == 'steelsword')
		{
			GetItemAttributes(itemId, abList);
			if (abList.Contains('SlashingDamage'))
			{
				attributeName = 'SlashingDamage';
				attributeLabel = GetLocStringByKeyExt("panel_inventory_tooltip_damage");
			}
			else if (abList.Contains('BludgeoningDamage'))
			{
				attributeName = 'BludgeoningDamage';
			}
			else if (abList.Contains('PiercingDamage'))
			{
				attributeName = 'PiercingDamage';
			}
			else
			{
				attributeName = 'PhysicalDamage';
			}
			if (attributeLabel == "")
			{
				attributeLabel = GetAttributeNameLocStr(attributeName, false);
			}
		}
		else
		{
			GetItemPrimaryStatImpl(categoryName, attributeLabel, attributeVal, attributeName);
		}
	}
	
	public function IsPrimaryStat(categoryName : name, attributeName : name, out attributeLabel : string) : bool
	{
		var attrValue : float;
		var attrName  : name;
		
		GetItemPrimaryStatImpl(categoryName, attributeLabel, attrValue, attrName);
		return attrName == attributeName;
	}
	
	private function GetItemPrimaryStatImpl(categoryName : name,  out attributeLabel : string, out attributeVal : float, out attributeName : name ) : void
	{
		attributeName = '';
		attributeLabel = "";
		switch (categoryName)
		{
			case 'steelsword':
				attributeName = 'SlashingDamage';
				attributeLabel = GetLocStringByKeyExt("panel_inventory_tooltip_damage");
				break;
			case 'silversword':
				attributeName = 'SilverDamage';
				attributeLabel = GetLocStringByKeyExt("panel_inventory_tooltip_damage");
				break;
			case 'armor':
			case 'gloves':
			case 'gloves':
			case 'boots':
			case 'pants':
				attributeName = 'armor';
				break;
			case 'potion':
			case 'oil':
				//attributeName = 'duration';
				break;
			case 'bolt':
			case 'petard':
				attributeName = 'PhysicalDamage';
				break;
			case 'crossbow':
			default:
				attributeLabel = "";
				attributeVal = 0;
				return;
				break;
		}
		
		if (attributeLabel == "")
		{
			attributeLabel = GetAttributeNameLocStr(attributeName, false);
		}
	}
	
	public function CanBeCompared(itemId : SItemUniqueId) : bool
	{
		var wplayer		     	: W3PlayerWitcher;
		var itemSlot     		: EEquipmentSlots;
		var equipedItem 		: SItemUniqueId;
		var horseManager		: W3HorseManager;
		
		var isArmorOrWeapon : bool;
		
		if (IsItemHorseItem(itemId))
		{
			horseManager = GetWitcherPlayer().GetHorseManager();
			
			if (!horseManager)
			{
				return false;
			}
			
			if (horseManager.IsItemEquipped(itemId))
			{
				return false;
			}
			
			itemSlot = GetHorseSlotForItem(itemId);
			equipedItem = horseManager.GetItemInSlot(itemSlot);
			if (!horseManager.GetInventoryComponent().IsIdValid(equipedItem))
			{
				return false;
			}
		}
		else
		{
			isArmorOrWeapon = IsItemAnyArmor(itemId) || IsItemWeapon(itemId);
			if (!isArmorOrWeapon)
			{
				return false;
			}
			
			wplayer = GetWitcherPlayer();
			if (wplayer.IsItemEquipped(itemId))
			{
				return false;
			}
			
			itemSlot = GetSlotForItemId(itemId);		
			wplayer.GetItemEquippedOnSlot(itemSlot, equipedItem);
			if (!wplayer.inv.IsIdValid(equipedItem))
			{
				return false;
			}
		}
		
		return true;
	}
	
	public function GetHorseSlotForItem(id : SItemUniqueId) : EEquipmentSlots
	{
		var tags : array<name>;
		
		GetItemTags(id, tags);
		
		if(tags.Contains('Saddle'))				return EES_HorseSaddle;
		else if(tags.Contains('HorseBag'))		return EES_HorseBag;
		else if(tags.Contains('Trophy'))		return EES_HorseTrophy;
		else if(tags.Contains('Blinders'))		return EES_HorseBlinders;
		else									return EES_InvalidSlot;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////  @SINGLETON ITEMS  ////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public final function SingletonItemRefillAmmo( id : SItemUniqueId, optional alchemyTableUsed : bool )
	{
		var l_bed		: W3WitcherBed;
		var refilledByBed : bool;
		
		refilledByBed = false;
		
		//Alchemy Table increases all the potions by 1
		if( FactsQuerySum( "PlayerInsideOuterWitcherHouse" ) >= 1 && FactsQuerySum( "AlchemyTableExists" ) >= 1 && !IsItemMutagenPotion( id ) )
		{
			l_bed = (W3WitcherBed)theGame.GetEntityByTag( 'witcherBed' );
			
			if( l_bed.GetWasUsed() || alchemyTableUsed )
			{
				SetItemModifierInt( id, 'ammo_current', SingletonItemGetMaxAmmo(id) + theGame.params.QUANTITY_INCREASED_BY_ALCHEMY_TABLE ) ;
				refilledByBed = true;
				if( !l_bed.GetWereItemsRefilled() )
				{
					l_bed.SetWereItemsRefilled( true );
				}
			}			
		}
		
		//regular refill
		if( !refilledByBed && SingletonItemGetAmmo( id ) < SingletonItemGetMaxAmmo( id ) )
		{
			SetItemModifierInt(id, 'ammo_current', SingletonItemGetMaxAmmo(id));
		}
		
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnAmmoChanged );
	}
	
	public function SingletonItemSetAmmo(id : SItemUniqueId, quantity : int)
	{
		var amount : int;
		
		if(ItemHasTag(id, theGame.params.TAG_INFINITE_AMMO))
		{
			amount = -1;
		}
		else
		{
			amount = Clamp(quantity, 0, SingletonItemGetMaxAmmo(id));
		}
		
		SetItemModifierInt(id, 'ammo_current', amount);
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnAmmoChanged );
	}
	
	public function SingletonItemAddAmmo(id : SItemUniqueId, quantity : int)
	{
		var ammo : int;
		
		if(quantity <= 0)
			return;
			
		ammo = GetItemModifierInt(id, 'ammo_current');
		
		if(ammo == -1)
			return;	//infinite, cannot add
			
		ammo = Clamp(ammo + quantity, 0, SingletonItemGetMaxAmmo(id));
		SetItemModifierInt(id, 'ammo_current', ammo);
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnAmmoChanged );
	}
	
	public function SingletonItemsRefillAmmo( optional alchemyTableUsed : bool ) : bool
	{
		var i : int;
		var singletonItems : array<SItemUniqueId>;
		var alco : SItemUniqueId;
		var arrStr : array<string>;
		var witcher : W3PlayerWitcher;
		var itemLabel : string;
	
		witcher = GetWitcherPlayer();
		if(GetEntity() == witcher && HasNotFilledSingletonItem( alchemyTableUsed ) )
		{
			alco = witcher.GetAlcoholForAlchemicalItemsRefill();
		
			if(!IsIdValid(alco))
			{
				//doesn't have alcohol that can be used to refill
				theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("message_common_alchemy_items_cannot_refill"));
				theSound.SoundEvent("gui_global_denied");
				
				return false;
			}
			else
			{
				//has alco to refill				
				arrStr.PushBack(GetItemName(alco));
				itemLabel = GetLocStringByKeyExt(GetItemLocalizedNameByUniqueID(alco));
				theGame.GetGuiManager().ShowNotification( itemLabel + " - " + GetLocStringByKeyExtWithParams("message_common_alchemy_items_refilled", , , arrStr));
				theSound.SoundEvent("gui_alchemy_brew");
				
				if(!ItemHasTag(alco, theGame.params.TAG_INFINITE_USE))
					RemoveItem(alco);
			}
		}
		
		singletonItems = GetSingletonItems();
		for(i=0; i<singletonItems.Size(); i+=1)
		{			
			SingletonItemRefillAmmo( singletonItems[i], alchemyTableUsed );
		}
		
		return true;
	}
	
	public function SingletonItemsRefillAmmoNoAlco(optional dontUpdateUI : bool)
	{
		var i : int;
		var singletonItems : array<SItemUniqueId>;
		var alco : SItemUniqueId;
		var arrStr : array<string>;
		var witcher : W3PlayerWitcher;
		var itemLabel : string;
	
		witcher = GetWitcherPlayer();
		if(!dontUpdateUI && GetEntity() == witcher && HasNotFilledSingletonItem())
		{
			//has alco to refill				
			arrStr.PushBack(GetItemName(alco));
			itemLabel = GetLocStringByKeyExt(GetItemLocalizedNameByUniqueID(alco));
			theGame.GetGuiManager().ShowNotification( itemLabel + " - " + GetLocStringByKeyExtWithParams("message_common_alchemy_items_refilled", , , arrStr));
			theSound.SoundEvent("gui_alchemy_brew");
		}
		
		singletonItems = GetSingletonItems();
		for(i=0; i<singletonItems.Size(); i+=1)
		{			
			SingletonItemRefillAmmo(singletonItems[i]);
		}
	}	
	
	//returns true if has at least one singleton item that does not have full ammo
	private final function HasNotFilledSingletonItem( optional alchemyTableUsed : bool ) : bool
	{
		var i : int;
		var singletonItems : array<SItemUniqueId>;
		var hasLab : bool;
		var l_bed : W3WitcherBed;
		
		//Alchemy Table increases all the potions by 1
		hasLab = false;
		if( FactsQuerySum( "PlayerInsideOuterWitcherHouse" ) >= 1 && FactsQuerySum( "AlchemyTableExists" ) >= 1 )
		{
			l_bed = (W3WitcherBed)theGame.GetEntityByTag( 'witcherBed' );			
			if( l_bed.GetWasUsed() || alchemyTableUsed )
			{
				hasLab = true;
			}
		}
		
		singletonItems = GetSingletonItems();
		for(i=0; i<singletonItems.Size(); i+=1)
		{			
			if( hasLab && !IsItemMutagenPotion( singletonItems[i] ) )
			{
				if(SingletonItemGetAmmo(singletonItems[i]) <= SingletonItemGetMaxAmmo(singletonItems[i]))
				{
					return true;
				}
			}
			else if(SingletonItemGetAmmo(singletonItems[i]) < SingletonItemGetMaxAmmo(singletonItems[i]))
			{
				return true;
			}
		}
		
		return false;
	}
	
	public function SingletonItemRemoveAmmo(itemID : SItemUniqueId, optional quantity : int)
	{
		var ammo : int;
		
		if(!IsItemSingletonItem(itemID) || ItemHasTag(itemID, theGame.params.TAG_INFINITE_AMMO))
			return;
		
		if(quantity <= 0)
			quantity = 1;
			
		ammo = GetItemModifierInt(itemID, 'ammo_current');
		ammo = Max(0, ammo - quantity);
		SetItemModifierInt(itemID, 'ammo_current', ammo);
		
		//count alchemy usage but only after nightmare
		if(ammo == 0 && ShouldProcessTutorial('TutorialAlchemyRefill') && FactsQuerySum("q001_nightmare_ended") > 0)
		{
			FactsAdd('tut_alch_refill', 1);
		}
		theGame.GetGlobalEventsManager().OnScriptedEvent( SEC_OnAmmoChanged );
	}
	
	public function SingletonItemGetAmmo(itemID : SItemUniqueId) : int
	{
		if(!IsItemSingletonItem(itemID))
			return 0;
		
		return GetItemModifierInt(itemID, 'ammo_current');
	}
	
	public function SingletonItemGetMaxAmmo(itemID : SItemUniqueId) : int
	{
		var ammo, i : int;
		var perk20Bonus, min, max : SAbilityAttributeValue;
		var atts : array<name>;
		var canUseSkill : bool;
		
		ammo = RoundMath(CalculateAttributeValue(GetItemAttributeValue(itemID, 'ammo')));
		
		if( !ItemHasTag( itemID, 'NoAdditionalAmmo' ) )
		{
			if(GetEntity() == GetWitcherPlayer() && ammo > 0)
			{
				if(IsItemBomb(itemID) && thePlayer.CanUseSkill(S_Alchemy_s08) )
				{
					ammo += thePlayer.GetSkillLevel(S_Alchemy_s08);
				}
				//mutagen 3
				if(thePlayer.HasBuff(EET_Mutagen03) && (IsItemBomb(itemID) || (!IsItemMutagenPotion(itemID) && IsItemPotion(itemID))) )
				{
					ammo += 1;
				}

				if( GetWitcherPlayer().IsSetBonusActive( EISB_RedWolf_2 ) && !IsItemMutagenPotion(itemID) )
				{
					theGame.GetDefinitionsManager().GetAbilityAttributeValue( GetSetBonusAbility( EISB_RedWolf_2 ), 'amount', min, max);
					ammo += (int)min.valueAdditive;
				}
							
				//Perk 20 - decreases amount of bombs in stack, but increases their damage
				if( IsItemBomb( itemID ) && thePlayer.CanUseSkill( S_Perk_20 ) &&  GetItemName( itemID ) != 'Snow Ball' )
				{
					GetItemAttributes( itemID, atts );
					canUseSkill = thePlayer.CanUseSkill( S_Alchemy_s10 );
					perk20Bonus = GetWitcherPlayer().GetSkillAttributeValue( S_Perk_20, 'stack_multiplier', false, false );
					
					for( i=0 ; i<atts.Size() ; i+=1 )
					{
						if( canUseSkill || IsDamageTypeNameValid( atts[i] ) )
						{
							ammo = RoundMath( ammo * perk20Bonus.valueMultiplicative );
							break;
						}
					}				
				}
			}
		}
		
		return ammo;
	}
	
	public function ManageSingletonItemsBonus()
	{
		var l_items			: array<SItemUniqueId>;
		var l_i				: int;
		var l_haveBombOrPot	: bool;
		
		l_items = GetSingletonItems();

		for( l_i = 0 ; l_i < l_items.Size() ; l_i += 1 )
		{
			if( IsItemPotion( l_items[ l_i ] ) || IsItemBomb( l_items[ l_i ] ) )
			{
				l_haveBombOrPot = true;
				if( SingletonItemGetMaxAmmo( l_items[ l_i ] ) >= SingletonItemGetAmmo( l_items[ l_i ] ) )
				{
					if( SingletonItemsRefillAmmo( true ) )
					{
						theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_common_alchemy_table_buff_applied" ),, true );
					}
					
					return;
				}
			}
		}
		
		if( !l_haveBombOrPot )
		{
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_common_alchemy_table_buff_no_items" ),, true );
			return;
		}
		
		theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_common_alchemy_table_buff_already_on" ),, true );
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////  @SLOTS  //////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public final function IsItemSteelSwordUsableByPlayer(item : SItemUniqueId) : bool
	{
		return ItemHasTag(item, theGame.params.TAG_PLAYER_STEELSWORD) && !ItemHasTag(item, 'SecondaryWeapon');
	}
	
	public final function IsItemSilverSwordUsableByPlayer(item : SItemUniqueId) : bool
	{
		return ItemHasTag(item, theGame.params.TAG_PLAYER_SILVERSWORD) && !ItemHasTag(item, 'SecondaryWeapon');
	}

	public final function IsItemFists(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'fist';}
	public final function IsItemWeapon(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'Weapon') || ItemHasTag(item, 'WeaponTab');}
	public final function IsItemCrossbow(item : SItemUniqueId) : bool						{return GetItemCategory(item) == 'crossbow';}
	public final function IsItemChestArmor(item : SItemUniqueId) : bool						{return GetItemCategory(item) == 'armor';}
	public final function IsItemBody(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'Body');}
	public final function IsRecipeOrSchematic( item : SItemUniqueId ) : bool				{return GetItemCategory(item) == 'alchemy_recipe' || GetItemCategory(item) == 'crafting_schematic'; } 
	public final function IsItemBoots(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'boots';}
	public final function IsItemGloves(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'gloves';}
	public final function IsItemPants(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'trousers' || GetItemCategory(item) == 'pants';}
	public final function IsItemTrophy(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'trophy';}
	public final function IsItemMask(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'mask';}
	public final function IsItemBomb(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'petard';}
	public final function IsItemBolt(item : SItemUniqueId) : bool							{return GetItemCategory(item) == 'bolt';}
	public final function IsItemUpgrade(item : SItemUniqueId) : bool						{return GetItemCategory(item) ==  'upgrade';}
	public final function IsItemTool(item : SItemUniqueId) : bool							{return GetItemCategory(item) ==  'tool';}
	public final function IsItemPotion(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'Potion');}
	public final function IsItemOil(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'SilverOil') || ItemHasTag(item, 'SteelOil');}
	public final function IsItemAnyArmor(item : SItemUniqueId) : bool						{return ItemHasTag(item, theGame.params.TAG_ARMOR);}
	public final function IsItemUpgradeable(item : SItemUniqueId) : bool					{return ItemHasTag(item, theGame.params.TAG_ITEM_UPGRADEABLE);}
	public final function IsItemIngredient(item : SItemUniqueId) : bool						{return ItemHasTag(item, 'AlchemyIngredient') || ItemHasTag(item, 'CraftingIngredient');}
	public final function IsItemDismantleKit(item : SItemUniqueId) : bool					{return ItemHasTag(item, 'DismantleKit');}
	public final function IsItemHorseBag(item : SItemUniqueId) : bool						{return ItemHasTag(item, 'HorseBag');}	
	public final function IsItemReadable(item : SItemUniqueId) : bool						{return ItemHasTag(item, 'ReadableItem');}
	public final function IsItemAlchemyItem(item : SItemUniqueId) : bool					{return IsItemOil(item) || IsItemPotion(item) || IsItemBomb(item); /*|| ItemHasTag(item, 'QuickSlot');*/ }	// #B
	public final function IsItemSingletonItem(item : SItemUniqueId) : bool 					{return ItemHasTag(item, theGame.params.TAG_ITEM_SINGLETON);}
	public final function IsItemQuest(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'Quest');}
	public final function IsItemFood(item : SItemUniqueId) : bool							{return ItemHasTag(item, 'Edibles') || ItemHasTag(item, 'Drinks');}
	public final function IsItemSecondaryWeapon(item : SItemUniqueId) : bool				{return ItemHasTag(item, 'SecondaryWeapon');}
	public final function IsItemHorseItem(item: SItemUniqueId) : bool						{return ItemHasTag(item, 'Saddle') || ItemHasTag(item, 'HorseBag') || ItemHasTag(item, 'Trophy') || ItemHasTag(item, 'Blinders'); }
	public final function IsItemSaddle(item: SItemUniqueId) : bool							{return ItemHasTag(item, 'Saddle');}
	public final function IsItemBlinders(item: SItemUniqueId) : bool						{return ItemHasTag(item, 'Blinders');}
	public final function IsItemDye( item : SItemUniqueId ) : bool							{ return ItemHasTag( item, 'mod_dye' ); }
	public final function IsItemUsable( item : SItemUniqueId ) : bool 						{ return GetItemCategory( item ) == 'usable'; }
	public final function IsItemJunk( item : SItemUniqueId ) : bool							{ return ItemHasTag( item,'junk' ) || GetItemCategory( item ) == 'junk' ; }
	public final function IsItemAlchemyIngredient(item : SItemUniqueId) : bool				{ return ItemHasTag( item, 'AlchemyIngredient' ); }
	public final function IsItemCraftingIngredient(item : SItemUniqueId) : bool				{ return ItemHasTag( item, 'CraftingIngredient' ); }
	public final function IsItemArmorReapairKit(item : SItemUniqueId) : bool				{ return ItemHasTag( item, 'ArmorReapairKit' ); }
	public final function IsItemWeaponReapairKit(item : SItemUniqueId) : bool				{ return ItemHasTag( item, 'WeaponReapairKit' ); }
	public final function IsQuickSlotItem( item : SItemUniqueId ) : bool 					{ return ItemHasTag( item, 'QuickSlot' ); }
	
	public final function IsItemNew( item : SItemUniqueId ) : bool
	{
		var uiData : SInventoryItemUIData;
		
		uiData = GetInventoryItemUIData( item );
		return uiData.isNew;
	}
	
	public final function IsItemMutagenPotion(item : SItemUniqueId) : bool
	{
		return IsItemPotion(item) && ItemHasTag(item, 'Mutagen');
	}
	
	public final function CanItemBeColored( item : SItemUniqueId) : bool
	{
		if ( RoundMath( CalculateAttributeValue( GetItemAttributeValue( item, 'quality' ) ) ) == 5 )
		{
			return true;
		}
		return false;	
	}

	public final function IsItemSetItem(item : SItemUniqueId) : bool
	{
		return
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_BEAR) ||
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_GRYPHON) ||
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_LYNX) ||
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_WOLF) ||
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_RED_WOLF) ||
			ItemHasTag( item, theGame.params.ITEM_SET_TAG_VAMPIRE ) ||
			ItemHasTag(item, theGame.params.ITEM_SET_TAG_VIPER);
	}
	
	public function GetArmorType(item : SItemUniqueId) : EArmorType
	{
		var isItemEquipped : bool;
		
		isItemEquipped = GetWitcherPlayer().IsItemEquipped(item);
		
		//GlyphWord bonuses
		if( thePlayer.HasAbility('Glyphword 2 _Stats', true) && isItemEquipped )
		{return EAT_Light;}
		if( thePlayer.HasAbility('Glyphword 3 _Stats', true) && isItemEquipped )
		{return EAT_Medium;}
		if( thePlayer.HasAbility('Glyphword 4 _Stats', true) && isItemEquipped )
		{return EAT_Heavy;}
	
		if(ItemHasTag(item, 'LightArmor'))
			return EAT_Light;
		else if(ItemHasTag(item, 'MediumArmor'))
			return EAT_Medium;
		else if(ItemHasTag(item, 'HeavyArmor'))
			return EAT_Heavy;
		
		return EAT_Undefined;
	}
	
	public final function GetAlchemyCraftableItems() : array<SItemUniqueId>
	{
		var items : array<SItemUniqueId>;
		var i : int;
		
		GetAllItems(items);
		
		for(i=items.Size()-1; i>=0; i-=1)
		{
			if(!IsItemPotion(items[i]) && !IsItemBomb(items[i]) && !IsItemOil(items[i]))
				items.EraseFast(i);
		}
		
		return items;
	}
	
	public function IsItemEncumbranceItem(item : SItemUniqueId) : bool
	{
		if(ItemHasTag(item, theGame.params.TAG_ENCUMBRANCE_ITEM_FORCE_YES))
			return true;
			
		if(ItemHasTag(item, theGame.params.TAG_ENCUMBRANCE_ITEM_FORCE_NO))
			return false;

		//#J added in IsItemAlchemyItem and IsItemIngredient to make it consisten with tooltip. Need to varify which is correct but this way makes most sense
		if (//	IsItemQuest(item)
				IsRecipeOrSchematic( item )
			||	IsItemBody( item )
		//	||	IsItemBolt(item)
		//	||	IsItemAlchemyItem(item)
		//	||	IsItemIngredient(item)
		//	||	IsItemTool(item)
		//	||	GetItemCategory(item) == 'misc'
		//	||	GetItemCategory(item) == 'usable'
		//	||	GetItemCategory(item) == 'book'
		//	||	GetItemCategory(item) == 'key'
		//	||	GetItemCategory(item) == 'trophy'
		//	||	GetItemCategory(item) == 'mask'
		//	||	GetItemCategory(item) == 'junk'
		//	||	GetItemCategory(item) == 'horse_bag'
			)
			return false;

		return true;
	}
	
	public function GetItemEncumbrance(item : SItemUniqueId) : float
	{
		var itemCategory : name;
		if ( IsItemEncumbranceItem( item ) )
		{
			itemCategory = GetItemCategory( item );
			if ( itemCategory == 'quest' || itemCategory == 'key' )
			{
				return 0.01 * GetItemQuantity( item );
			}
			else if ( itemCategory == 'usable' || itemCategory == 'upgrade' || itemCategory == 'junk' )
			{
				return 0.01 + GetItemWeight( item ) * GetItemQuantity( item ) * 0.2;
			}
			else if ( IsItemAlchemyItem( item ) || IsItemIngredient( item ) || IsItemFood( item ) || IsItemReadable( item ) )
			{
				return 0.0;
			}
			else
			{
				return 0.01 + GetItemWeight( item ) * GetItemQuantity( item ) * 0.5;
			}
		}
		return 0;
	}
	
	public function GetFilterTypeByItem( item : SItemUniqueId ) : EInventoryFilterType
	{
		var filterType : EInventoryFilterType;
					
		if( ItemHasTag( item, 'Quest' ) )
		{
			return IFT_QuestItems;
		}				
		else if( IsItemIngredient( item ) )
		{
			return IFT_Ingredients;
		}				
		else if( IsItemAlchemyItem(item) ) 
		{
			return IFT_AlchemyItems;
		}				
		else if( IsItemAnyArmor(item) )
		{
			return IFT_Armors;
		}				
		else if( IsItemWeapon( item ) )
		{
			return IFT_Weapons;
		}				
		else
		{
			return IFT_Default;
		}
	}	
	
	//returns true if given item is an item that is placed in quickslots
	public function IsItemQuickslotItem(item : SItemUniqueId) : bool
	{
		return IsSlotQuickslot( GetSlotForItemId(item) );
	}
	
	public function GetCrossbowAmmo(id : SItemUniqueId) : int
	{
		if(!IsItemCrossbow(id))
			return -1;
			
		return (int)CalculateAttributeValue(GetItemAttributeValue(id, 'ammo'));
	}
		
	//Returns appropriate slot for given item. If it's a slot that exists in multiple numbers (e.g. quickslot) tries to find first free one. If there is no free one
	//then returns the default slot for this group.
	public function GetSlotForItemId(item : SItemUniqueId) : EEquipmentSlots
	{
		var tags : array<name>;
		var player : W3PlayerWitcher;
		var slot : EEquipmentSlots;
		
		player = ((W3PlayerWitcher)GetEntity());
		
		GetItemTags(item, tags);
		slot = GetSlotForItem( GetItemCategory(item), tags, player );
		
		if(!player)
			return slot;
		
		if(IsMultipleSlot(slot))
		{
			if(slot == EES_Petard1 && player.IsAnyItemEquippedOnSlot(slot))
			{
				if(!player.IsAnyItemEquippedOnSlot(EES_Petard2))
					slot = EES_Petard2;
			}
			else if(slot == EES_Quickslot1 && player.IsAnyItemEquippedOnSlot(slot))
			{
				if(!player.IsAnyItemEquippedOnSlot(EES_Quickslot2))
					slot = EES_Quickslot2;
			}
			else if(slot == EES_Potion1 && player.IsAnyItemEquippedOnSlot(EES_Potion1))
			{
				if(!player.IsAnyItemEquippedOnSlot(EES_Potion2))
				{
					slot = EES_Potion2;
				}
				else
				{
					if(!player.IsAnyItemEquippedOnSlot(EES_Potion3))
					{
						slot = EES_Potion3;
					}
					else
					{
						if(!player.IsAnyItemEquippedOnSlot(EES_Potion4))
						{
							slot = EES_Potion4;
						}
					}
				}
			}
			else if(slot == EES_PotionMutagen1 && player.IsAnyItemEquippedOnSlot(slot))
			{
				if(!player.IsAnyItemEquippedOnSlot(EES_PotionMutagen2))
				{
					slot = EES_PotionMutagen2;
				}
				else
				{
					if(!player.IsAnyItemEquippedOnSlot(EES_PotionMutagen3))
					{
						slot = EES_PotionMutagen3;
					}
					else
					{
						if(!player.IsAnyItemEquippedOnSlot(EES_PotionMutagen4))
						{
							slot = EES_PotionMutagen4;
						}
					}
				}
			}
			else if(slot == EES_SkillMutagen1 && player.IsAnyItemEquippedOnSlot(slot))
			{
				if(!player.IsAnyItemEquippedOnSlot(EES_SkillMutagen2))
				{
					slot = EES_SkillMutagen2;
				}
				else
				{
					if(!player.IsAnyItemEquippedOnSlot(EES_SkillMutagen3))
					{
						slot = EES_SkillMutagen3;
					}
					else
					{
						if(!player.IsAnyItemEquippedOnSlot(EES_SkillMutagen4))
						{
							slot = EES_SkillMutagen4;
						}
					}
				}
			}
		}
		
		return slot;
	}
	
	
	
	public function GetAllWeapons() : array<SItemUniqueId>
	{
		return GetItemsByTag('Weapon');	
	}
	
	/*
		Quest function to get specific items - do not use outisde of quest function!
		
		Gets items of given types, except the ones that cannot be dropped.
	*/
	public function GetSpecifiedPlayerItemsQuest(steelSword, silverSword, armor, boots, gloves, pants, trophy, mask, bombs, crossbow, secondaryWeapon, equippedOnly : bool) : array<SItemUniqueId>
	{	
		var items, allItems : array<SItemUniqueId>;
		var i : int;
	
		GetAllItems(allItems);
		
		for(i=0; i<allItems.Size(); i+=1)
		{
			if(
				(steelSword && IsItemSteelSwordUsableByPlayer(allItems[i])) ||
				(silverSword && IsItemSilverSwordUsableByPlayer(allItems[i])) ||
				(armor && IsItemChestArmor(allItems[i])) ||
				(boots && IsItemBoots(allItems[i])) ||
				(gloves && IsItemGloves(allItems[i])) ||
				(pants && IsItemPants(allItems[i])) ||
				(trophy && IsItemTrophy(allItems[i])) ||
				(mask && IsItemMask(allItems[i])) ||
				(bombs && IsItemBomb(allItems[i])) ||
				(crossbow && (IsItemCrossbow(allItems[i]) || IsItemBolt(allItems[i]))) ||
				(secondaryWeapon && IsItemSecondaryWeapon(allItems[i]))
			)
			{
				if(!equippedOnly || (equippedOnly && ((W3PlayerWitcher)GetEntity()) && GetWitcherPlayer().IsItemEquipped(allItems[i])) )
				{
					if(!ItemHasTag(allItems[i], 'NoDrop'))
						items.PushBack(allItems[i]);
				}
			}
		}
		
		return items;		
	}	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//Called BEFORE the item is removed from inventory
	event OnItemRemoved( itemId : SItemUniqueId, quantity : int )
	{
		var ent				: CGameplayEntity;
		var crossbows : array<SItemUniqueId>;
		var witcher : W3PlayerWitcher;
		var refill : W3RefillableContainer;
		
		witcher = GetWitcherPlayer();
		//if player
		if(GetEntity() == witcher)
		{
			//update encumbrance
			//if(IsItemEncumbranceItem(itemId)) // #B there is no sense in calling it here, "Called BEFORE the item is removed from inventory"
			//	GetWitcherPlayer().UpdateEncumbrance();
			
			//remove infinite bolts if player has no crossbow
			if(IsItemCrossbow(itemId) && HasInfiniteBolts())
			{
				crossbows = GetItemsByCategory('crossbow');
				crossbows.Remove(itemId);
				
				if(crossbows.Size() == 0)
				{
					RemoveItemByName('Bodkin Bolt', GetItemQuantityByName('Bodkin Bolt'));
					RemoveItemByName('Harpoon Bolt', GetItemQuantityByName('Harpoon Bolt'));
				}
			}
			else if(IsItemBolt(itemId) && witcher.IsItemEquipped(itemId) && witcher.inv.GetItemQuantity(itemId) == quantity)
			{
				//losing all equipped bolts
				witcher.UnequipItem(itemId);
			}
			
			//removing equipped crossbow
			if(IsItemCrossbow(itemId) && witcher.IsItemEquipped(itemId) && witcher.rangedWeapon)
			{
				witcher.rangedWeapon.ClearDeployedEntity(true);
				witcher.rangedWeapon = NULL;
			}
			if( GetItemCategory(itemId) == 'usable' )
			{
				if(witcher.IsHoldingItemInLHand() && itemId ==  witcher.currentlyEquipedItemL )
				{
					witcher.HideUsableItem(true);
				}
			}
			
			//failsafe for removing equipped item without proper checks
			if(witcher.IsItemEquipped(itemId) && quantity >= witcher.inv.GetItemQuantity(itemId))
				witcher.UnequipItem(itemId);
		}
		
		//if removing currently held weapon (or mounted - Ciri has issues with her Held weapons not being considered held!)
		if(GetEntity() == thePlayer && IsItemWeapon(itemId) && (IsItemHeld(itemId) || IsItemMounted(itemId) ))
		{
			thePlayer.OnHolsteredItem(GetItemCategory(itemId),'r_weapon');
		}
		
		//callback to the entity
		ent = (CGameplayEntity)GetEntity();
		if(ent)
			ent.OnItemTaken( itemId, quantity );
			
		//refillable container
		if(IsLootRenewable())
		{
			refill = (W3RefillableContainer)GetEntity();
			if(refill)
				refill.AddTimer('Refill', 20, true);
		}
	}
	
	//FIXME URGENT - what if player is not spawned yet?
	function GenerateItemLevel( item : SItemUniqueId, rewardItem : bool )
	{
		var stat : SAbilityAttributeValue;
		var playerLevel : int;
		var lvl, i : int;
		var quality : int;
		var ilMin, ilMax : int;
		
		playerLevel = GetWitcherPlayer().GetLevel();

		lvl = playerLevel - 1;

		// W3MOD - MAS - Merchants should offer items beyond the player's level.
		if ( ( W3MerchantNPC )GetEntity() )
		{
			lvl = RoundF( playerLevel + RandRangeF( 2, 0 ) );
			AddItemTag( item, 'AutogenUseLevelRange' );
		}
		else if ( rewardItem )
		{
			lvl = RoundF( playerLevel + RandRangeF( 1, 0 ) );
		}
		else if ( ItemHasTag( item, 'AutogenUseLevelRange') )
		{
			quality = RoundMath( CalculateAttributeValue( GetItemAttributeValue( item, 'quality' ) ) );
			ilMin = RoundMath(CalculateAttributeValue( GetItemAttributeValue( item, 'item_level_min' ) ));
			ilMax = RoundMath(CalculateAttributeValue( GetItemAttributeValue( item, 'item_level_max' ) ));
			
			lvl += 1; //as it is for some reason decreased in on of the futher funtions ...
			if ( !ItemHasTag( item, 'AutogenForceLevel') )
				lvl += RoundMath(RandRangeF( 1, -1 ));
			
			if ( FactsQuerySum("NewGamePlus") > 0 )
			{
				if ( lvl < ilMin + theGame.params.GetNewGamePlusLevel() ) lvl = ilMin + theGame.params.GetNewGamePlusLevel();
				if ( lvl > ilMax + theGame.params.GetNewGamePlusLevel() ) lvl = ilMax + theGame.params.GetNewGamePlusLevel();
			}
			else
			{
				if ( lvl < ilMin ) lvl = ilMin;
				if ( lvl > ilMax ) lvl = ilMax;
			}
			
			if ( quality == 5 ) lvl += 2; 
			if ( quality == 4 ) lvl += 1;
			if ( (quality == 5 || quality == 4) && ItemHasTag(item, 'EP1') ) lvl += 1;
		}
		else if ( !ItemHasTag( item, 'AutogenForceLevel') )
		{
			quality = RoundMath( CalculateAttributeValue( GetItemAttributeValue( item, 'quality' ) ) );

			if ( quality == 5 )
			{
				lvl = RoundF( playerLevel + RandRangeF( 2, 0 ) );
			}
			else if ( quality == 4 )
			{
				lvl = RoundF( playerLevel + RandRangeF( 1, -2 ) );
			}
			else if ( quality == 3 )
			{
				lvl = RoundF( playerLevel + RandRangeF( -1, -3 ) );
				
				if ( RandF() > 0.9 )
				{
					lvl =  playerLevel;
				}
			}
			else if ( quality == 2 )
			{
				lvl = RoundF( playerLevel + RandRangeF( -2, -5 ) );
				
				if ( RandF() > 0.95 )
				{
					lvl =  playerLevel;
				}
			}
			else
			{
				lvl = RoundF( playerLevel + RandRangeF( -2, -8 ) );
				
				if ( RandF() == 0 )
				{
					lvl = playerLevel;
				}
			}
		}
		
		if (FactsQuerySum("StandAloneEP1") > 0)
			lvl = GetWitcherPlayer().GetLevel() - 1;
			
		
		if ( FactsQuerySum("NewGamePlus") > 0 && !ItemHasTag( item, 'AutogenUseLevelRange') )
		{	
			if ( quality == 5 ) lvl += 2; 
			if ( quality == 4 ) lvl += 1;
		}
			
		if ( lvl < 1 ) lvl = 1; 
		if ( lvl > GetWitcherPlayer().GetMaxLevel() ) lvl = GetWitcherPlayer().GetMaxLevel();
		
		if ( ItemHasTag( item, 'PlayerSteelWeapon' ) && !( ItemHasAbility( item, 'autogen_steel_base' ) || ItemHasAbility( item, 'autogen_fixed_steel_base' ) )  ) // STEEL SWORD
		{
			if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_steel_base') )
				return;
		
			if ( ItemHasTag(item, 'AutogenUseLevelRange') )
				AddItemCraftedAbility(item, 'autogen_fixed_steel_base' ); 
			else
				AddItemCraftedAbility(item, 'autogen_steel_base' );
				
			for( i=0; i<lvl; i+=1 ) 
			{
				if (FactsQuerySum("StandAloneEP1") > 0)
				{
					AddItemCraftedAbility(item, 'autogen_fixed_steel_dmg', true );
					continue;
				}
				
				if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 ) 
					AddItemCraftedAbility(item, 'autogen_fixed_steel_dmg', true );
				else
					AddItemCraftedAbility(item, 'autogen_steel_dmg', true ); 
			}
		}
		else if ( ItemHasTag( item, 'PlayerSilverWeapon' ) && !( ItemHasAbility( item, 'autogen_silver_base' ) || ItemHasAbility( item, 'autogen_fixed_silver_base' ) ) ) // SILVER SWORD
		{
			if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_silver_base') )
				return;
			
			if ( ItemHasTag(item, 'AutogenUseLevelRange') )
				AddItemCraftedAbility(item, 'autogen_fixed_silver_base' ); 
			else
				AddItemCraftedAbility(item, 'autogen_silver_base' ); 
				
			for( i=0; i<lvl; i+=1 ) 
			{
				if (FactsQuerySum("StandAloneEP1") > 0)
				{
					AddItemCraftedAbility(item, 'autogen_fixed_silver_dmg', true ); 
					continue;
				}
			
				if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 ) 
					AddItemCraftedAbility(item, 'autogen_fixed_silver_dmg', true ); 
				else
					AddItemCraftedAbility(item, 'autogen_silver_dmg', true ); 
			}
		}
		else if ( GetItemCategory( item ) == 'armor' && !( ItemHasAbility( item, 'autogen_armor_base' ) || ItemHasAbility( item, 'autogen_fixed_armor_base' ) ) ) // Armor
		{
			if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_armor_base') )
				return;
				
			if ( ItemHasTag(item, 'AutogenUseLevelRange') )
				AddItemCraftedAbility(item, 'autogen_fixed_armor_base' ); 
			else
				AddItemCraftedAbility(item, 'autogen_armor_base' ); 
				
			for( i=0; i<lvl; i+=1 ) 
			{
				if (FactsQuerySum("StandAloneEP1") > 0)
				{
					AddItemCraftedAbility(item, 'autogen_fixed_armor_armor', true ); 
					continue;
				}
			
				if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag( item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 ) 
					AddItemCraftedAbility(item, 'autogen_fixed_armor_armor', true ); 
				else
					AddItemCraftedAbility(item, 'autogen_armor_armor', true );		
			}
		}
		else if ( ( GetItemCategory( item ) == 'boots' || GetItemCategory( item ) == 'pants' ) && !( ItemHasAbility( item, 'autogen_pants_base' ) || ItemHasAbility( item, 'autogen_fixed_pants_base' ) ) ) // Pants and boots
		{
			if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_pants_base') )
				return;
				
			if ( ItemHasTag(item, 'AutogenUseLevelRange') )
				AddItemCraftedAbility(item, 'autogen_fixed_pants_base' ); 
			else 
				AddItemCraftedAbility(item, 'autogen_pants_base' ); 
				
			for( i=0; i<lvl; i+=1 ) 
			{
				if (FactsQuerySum("StandAloneEP1") > 0)
				{
					AddItemCraftedAbility(item, 'autogen_fixed_pants_armor', true ); 
					continue;
				}
			
				if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag( item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 ) 
					AddItemCraftedAbility(item, 'autogen_fixed_pants_armor', true ); 
				else
					AddItemCraftedAbility(item, 'autogen_pants_armor', true ); 
			}
		}
		else if ( GetItemCategory( item ) == 'gloves' && !( ItemHasAbility( item, 'autogen_gloves_base' ) || ItemHasAbility( item, 'autogen_fixed_gloves_base' ) ) ) // Gloves
		{
			if ( ItemHasTag(item, 'AutogenUseLevelRange') && ItemHasAbility(item, 'autogen_fixed_gloves_base') )
				return;
				
			if ( ItemHasTag(item, 'AutogenUseLevelRange') )
				AddItemCraftedAbility(item, 'autogen_fixed_gloves_base' ); 
			else
				AddItemCraftedAbility(item, 'autogen_gloves_base' ); 
				
			for( i=0; i<lvl; i+=1 ) 
			{
				if (FactsQuerySum("StandAloneEP1") > 0)
				{
					AddItemCraftedAbility(item, 'autogen_fixed_gloves_armor', true ); 
					continue;
				}
			
				if ( ItemHasTag( item, 'AutogenForceLevel') || ItemHasTag(item, 'AutogenUseLevelRange') || FactsQuerySum("NewGamePlus") > 0 ) 
					AddItemCraftedAbility(item, 'autogen_fixed_gloves_armor', true ); 
				else
					AddItemCraftedAbility(item, 'autogen_gloves_armor', true );
			}
		}	
	}
		
	//Called AFTER the item was added to inventory
	event OnItemAdded(data : SItemChangedData)
	{
		var i, j : int;
		var ent	: CGameplayEntity;
		var allCardsNames, foundCardsNames : array<name>;
		var allStringNamesOfCards : array<string>;
		var foundCardsStringNames : array<string>;
		var gwintCards : array<SItemUniqueId>;
		var itemName : name;
		var witcher : W3PlayerWitcher;
		var itemCategory : name;
		var dm : CDefinitionsManagerAccessor;
		var locKey : string;
		var leaderCardsHack : array<name>;
		
		var hud : CR4ScriptedHud;
		var journalUpdateModule : CR4HudModuleJournalUpdate;
		var itemId : SItemUniqueId;
		
		var isItemShematic : bool;
		
		var ngp : bool;
		
		ent = (CGameplayEntity)GetEntity();
RER_onItemAdded(this, data);		
		itemId = data.ids[0];
		
		//inform GUI
		if( data.informGui )
		{
			recentlyAddedItems.PushBack( itemId );
			if( ItemHasTag( itemId, 'FocusObject' ) )
			{
				GetWitcherPlayer().GetMedallion().Activate( true, 3.0);
			} 
		}
		
		//if item should be auto balanced - do it
		if ( ItemHasTag(itemId, 'Autogen') ) 
		{
			GenerateItemLevel( itemId, false );
		}
		
		witcher = GetWitcherPlayer();
		
		//Items with quality and stats change
		if(ent == witcher || ((W3MerchantNPC)ent) )
		{
			ngp = FactsQuerySum("NewGamePlus") > 0;
			for(i=0; i<data.ids.Size(); i+=1)
			{
				//Process items that do not have stats changed already
				if ( GetItemModifierInt(data.ids[i], 'ItemQualityModified') <= 0 )
					AddRandomEnhancementToItem(data.ids[i]);
				//Safeguard against unwanted level decrease for DLC items
				if ( ngp )
					SetItemModifierInt(data.ids[i], 'DoNotAdjustNGPDLC', 1);	
				
				itemName = GetItemName(data.ids[i]);
				// For NG+ items need to increase in level to match NG+
				if ( ngp && GetItemModifierInt(data.ids[i], 'NGPItemAdjusted') <= 0 && !ItemHasTag(data.ids[i], 'Autogen') )
				{
					IncreaseNGPItemlevel(data.ids[i]);
				}
				
			}
		}
		if(ent == witcher)
		{
			for(i=0; i<data.ids.Size(); i+=1)
			{	
				//if gwint card then progress achievement
				if( ItemHasTag( itemId, theGame.params.GWINT_CARD_ACHIEVEMENT_TAG ) || !FactsDoesExist( "fix_for_gwent_achievement_bug_121588" ) )
				{
					//Achievement hack for leaders as they use unique localisation key in XML
					leaderCardsHack.PushBack('gwint_card_emhyr_gold');
					leaderCardsHack.PushBack('gwint_card_emhyr_silver');
					leaderCardsHack.PushBack('gwint_card_emhyr_bronze');
					leaderCardsHack.PushBack('gwint_card_foltest_gold');
					leaderCardsHack.PushBack('gwint_card_foltest_silver');
					leaderCardsHack.PushBack('gwint_card_foltest_bronze');
					leaderCardsHack.PushBack('gwint_card_francesca_gold');
					leaderCardsHack.PushBack('gwint_card_francesca_silver');
					leaderCardsHack.PushBack('gwint_card_francesca_bronze');
					leaderCardsHack.PushBack('gwint_card_eredin_gold');
					leaderCardsHack.PushBack('gwint_card_eredin_silver');
					leaderCardsHack.PushBack('gwint_card_eredin_bronze');
					
					dm = theGame.GetDefinitionsManager();
					//get max count from XML
					allCardsNames = theGame.GetDefinitionsManager().GetItemsWithTag(theGame.params.GWINT_CARD_ACHIEVEMENT_TAG);
					
					//get all cards in inventory
					gwintCards = GetItemsByTag(theGame.params.GWINT_CARD_ACHIEVEMENT_TAG);

					//Achievement hack for leaders as they use unique localisation key in XML
					allStringNamesOfCards.PushBack('gwint_name_emhyr');
					allStringNamesOfCards.PushBack('gwint_name_emhyr');
					allStringNamesOfCards.PushBack('gwint_name_emhyr');
					allStringNamesOfCards.PushBack('gwint_name_foltest');
					allStringNamesOfCards.PushBack('gwint_name_foltest');
					allStringNamesOfCards.PushBack('gwint_name_foltest');
					allStringNamesOfCards.PushBack('gwint_name_francesca');
					allStringNamesOfCards.PushBack('gwint_name_francesca');
					allStringNamesOfCards.PushBack('gwint_name_francesca');
					allStringNamesOfCards.PushBack('gwint_name_eredin');
					allStringNamesOfCards.PushBack('gwint_name_eredin');
					allStringNamesOfCards.PushBack('gwint_name_eredin');
					
					//Count only UNIQUE cards (with the same localisation key name)
					for(j=0; j<allCardsNames.Size(); j+=1)
					{
						itemName = allCardsNames[j];
						locKey = dm.GetItemLocalisationKeyName(allCardsNames[j]);
						if (!allStringNamesOfCards.Contains(locKey))
						{
							allStringNamesOfCards.PushBack(locKey);
						}
					}
					
					//If minimum amount needed for achievement (120 unique cards) - Count only UNIQUE cards (with the same localisation key name)
					if(gwintCards.Size() >= allStringNamesOfCards.Size())
					{
						foundCardsNames.Clear();
						for(j=0; j<gwintCards.Size(); j+=1)
						{
							itemName = GetItemName(gwintCards[j]);
							locKey = dm.GetItemLocalisationKeyName(itemName);
							// Hack for Leader Cards as they have the same loc key name
							if(!foundCardsStringNames.Contains(locKey) || leaderCardsHack.Contains(itemName))
							{
								foundCardsStringNames.PushBack(locKey);
							}
						}

						if(foundCardsStringNames.Size() >= allStringNamesOfCards.Size())
						{
							theGame.GetGamerProfile().AddAchievement(EA_GwintCollector);
							FactsAdd("gwint_all_cards_collected", 1, -1);
						}
					}
					
					if(!FactsDoesExist("fix_for_gwent_achievement_bug_121588"))
						FactsAdd("fix_for_gwent_achievement_bug_121588", 1, -1);
				}
				
				itemCategory = GetItemCategory( itemId );
				isItemShematic = itemCategory == 'alchemy_recipe' ||  itemCategory == 'crafting_schematic';
				
				if( isItemShematic )
				{
					ReadSchematicsAndRecipes( itemId );
				}					
				
				//gwent cards
				if( ItemHasTag( data.ids[i], 'GwintCard'))
				{
					witcher.AddGwentCard(GetItemName(data.ids[i]), data.quantity);
				}
				
				// book
				
				if( !isItemShematic && ( this.ItemHasTag( itemId, 'ReadableItem' ) || this.ItemHasTag( itemId, 'Painting' ) ) && !this.ItemHasTag( itemId, 'NoNotification' ) )
				{
					hud = (CR4ScriptedHud)theGame.GetHud();
					if( hud )
					{
						journalUpdateModule = (CR4HudModuleJournalUpdate)hud.GetHudModule( "JournalUpdateModule" );
						if( journalUpdateModule )
						{
							journalUpdateModule.AddQuestBookInfo( itemId );
						}
					}
				}				
			}
		}
		
		//singleton item ammo initialize
		if( IsItemSingletonItem( itemId ) )
		{
			for(i=0; i<data.ids.Size(); i+=1)
			{
				if(!GetItemModifierInt(data.ids[i], 'is_initialized', 0))
				{
					SingletonItemRefillAmmo(data.ids[i]);
					SetItemModifierInt(data.ids[i], 'is_initialized', 1);
				}
			}			
		}
		
		//callback to the entity
		if(ent)
			ent.OnItemGiven(data);
	}
	
	public function AddRandomEnhancementToItem(item : SItemUniqueId)
	{
		var itemCategory 	: name;
		var itemQuality		: int;
		var ability			: name;
		var ent				: CGameplayEntity;
		//var dm				: CDefinitionsManagerAccessor;
		
		//dm = theGame.GetDefinitionsManager();
		
		if( ItemHasTag(item, 'DoNotEnhance') )
		{
			SetItemModifierInt(item, 'ItemQualityModified', 1);
			return;
		}
		
		itemCategory = GetItemCategory(item);
		itemQuality = RoundMath(CalculateAttributeValue(GetItemAttributeValue(item, 'quality' )));
		
		if ( itemCategory == 'armor' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_armor'; 			
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkArmorAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_armor'; 	
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkArmorAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkArmorAbility(), true);
					break;
				default : break;
			}
		}
		else if ( itemCategory == 'gloves' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_gloves'; 		
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkGlovesAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_gloves'; 	
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}		
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalGlovesAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkGlovesAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalGlovesAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkGlovesAbility(), true);
					break;
				default : break;
			}
		}
		else if ( itemCategory == 'pants' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_pants'; 			
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkPantsAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_pants'; 	
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalPantsAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkPantsAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalPantsAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkPantsAbility(), true);
					break;
				default : break;
			}
		}
		else if ( itemCategory == 'boots' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_boots'; 			
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkBootsAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_boots'; 		
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalBootsAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkBootsAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalBootsAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkBootsAbility(), true);
					break;
				default : break;
			}
		}
		else if ( itemCategory == 'steelsword' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_steelsword'; 	
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_steelsword'; 	
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalWeaponAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalWeaponAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					break;
				default : break;
			}
		}
		else if ( itemCategory == 'silversword' )
		{
			switch ( itemQuality )
			{
				case 2 : 
					ability = 'quality_masterwork_silversword';	
					AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					break;
				case 3 : 
					ability = 'quality_magical_silversword'; 	
					if ( ItemHasTag(item, 'EP1') )
					{
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalArmorAbility(), true);
						break;
					}
					// first ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalWeaponAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					//second ability
					if ( RandF() > 0.5 )
						AddItemCraftedAbility(item, theGame.params.GetRandomMagicalWeaponAbility(), true);
					else
						AddItemCraftedAbility(item, theGame.params.GetRandomMasterworkWeaponAbility(), true);
					break;
					
				default : break;
			}
		}
			
		if(IsNameValid(ability))
		{
			AddItemCraftedAbility(item, ability, false);
			SetItemModifierInt(item, 'ItemQualityModified', 1);
		}
	}
	
	public function IncreaseNGPItemlevel(item : SItemUniqueId)
	{
		var i, diff : int;
		
		diff = theGame.params.NewGamePlusLevelDifference();
		
		if (diff > 0)
		{
			if ( ItemHasTag( item, 'PlayerSteelWeapon' ) ) // STEEL SWORD
			{	
				for( i=0; i<diff; i+=1 ) 
				{
					AddItemCraftedAbility(item, 'autogen_fixed_steel_dmg', true );
				}
			}
			else if ( ItemHasTag( item, 'PlayerSilverWeapon' ) ) // SILVER SWORD
			{
				for( i=0; i<diff; i+=1 ) 
				{
					AddItemCraftedAbility(item, 'autogen_fixed_silver_dmg', true ); 
				}
			}
			else if ( IsItemChestArmor(item) ) // Armor
			{	
				for( i=0; i<diff; i+=1 ) 
				{
					AddItemCraftedAbility(item, 'autogen_fixed_armor_armor', true );		
				}
			}
			else if ( IsItemBoots(item) || IsItemPants(item) ) // Pants and boots
			{				
				for( i=0; i<diff; i+=1 ) 
				{
					AddItemCraftedAbility(item, 'autogen_fixed_pants_armor', true ); 
				}
			}
			else if ( IsItemGloves(item) ) // Gloves
			{			
				for( i=0; i<diff; i+=1 ) 
				{
					AddItemCraftedAbility(item, 'autogen_fixed_gloves_armor', true );
				}
			}	
		}
		
		SetItemModifierInt(item, 'NGPItemAdjusted', 1);
	}
	
	public function GetItemQuality( itemId : SItemUniqueId ) : int
	{
		var itemQuality : float;
		var itemQualityAtribute	: SAbilityAttributeValue;
		var excludedTags : array<name>;
		var tempItemQualityAtribute	: SAbilityAttributeValue;
	
		//get attribute but exclude attribute value of applied oil!!
		excludedTags.PushBack(theGame.params.OIL_ABILITY_TAG);
		itemQualityAtribute = GetItemAttributeValue( itemId, 'quality', excludedTags, true );
		
		itemQuality = itemQualityAtribute.valueAdditive;
		if( itemQuality == 0 )
		{
			itemQuality = 1;
		}
		return RoundMath(itemQuality);
	}
	
	public function GetItemQualityFromName( itemName : name, out min : int, out max : int)
	{
		var dm : CDefinitionsManagerAccessor;
		var attributeName : name;
		var attributes, itemAbilities : array<name>;
		var attributeMin, attributeMax : SAbilityAttributeValue;
		
		var tmpInt : int;
		var tmpArray : array<float>;
		
		dm = theGame.GetDefinitionsManager();
		
		dm.GetItemAbilitiesWithWeights(itemName, GetEntity() == thePlayer, itemAbilities, tmpArray, tmpInt, tmpInt);
		attributes = dm.GetAbilitiesAttributes(itemAbilities);
		for (tmpInt = 0; tmpInt < attributes.Size(); tmpInt += 1)
		{
			if (attributes[tmpInt] == 'quality')
			{
				dm.GetAbilitiesAttributeValue(itemAbilities, 'quality', attributeMin, attributeMax);
				min = RoundMath(CalculateAttributeValue(attributeMin));
				max = RoundMath(CalculateAttributeValue(attributeMax));
				break;
			}
		}
	}
	
	public function GetRecentlyAddedItems() : array<SItemUniqueId> //#B
	{
		return recentlyAddedItems;
	}
	
	public function GetRecentlyAddedItemsListSize() : int //#B
	{
		return recentlyAddedItems.Size();
	}
	
	public function RemoveItemFromRecentlyAddedList( itemId : SItemUniqueId ) : bool //#B
	{
		var i : int;
		
		for( i = 0; i < recentlyAddedItems.Size(); i += 1 )
		{
			if( recentlyAddedItems[i] == itemId )
			{
				recentlyAddedItems.EraseFast( i );
				return true;
			}
		}
		
		return false;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// callbacks
	
	import final function NotifyScriptedListeners( notify : bool );
	
	var listeners : array< IInventoryScriptedListener >;
	
	function AddListener( listener : IInventoryScriptedListener )
	{	
		if ( listeners.FindFirst( listener ) == -1 )
		{
			listeners.PushBack( listener );
			if ( listeners.Size() == 1 )
			{
				NotifyScriptedListeners( true );
			}		
		}	
	}
	
	function RemoveListener( listener : IInventoryScriptedListener )
	{	
		if ( listeners.Remove( listener ) )
		{
			if ( listeners.Size() == 0 )
			{
				NotifyScriptedListeners( false );
			}		
		}	
	}
	
	event OnInventoryScriptedEvent( eventType : EInventoryEventType, itemId : SItemUniqueId, quantity : int, fromAssociatedInventory : bool )
	{
		var i, size : int;
		
		size = listeners.Size();
		for (i=size-1; i>=0; i-=1 )		//it seems listeners erase themselves so array iterator gets corrupted
		{
			listeners[i].OnInventoryScriptedEvent( eventType, itemId, quantity, fromAssociatedInventory );
		}
		
		//update encumbrance
		if(GetEntity() == GetWitcherPlayer() && (eventType == IET_ItemRemoved || eventType == IET_ItemQuantityChanged) )
			GetWitcherPlayer().UpdateEncumbrance();
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////   @MUTAGENS   /////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public final function GetMutationResearchPoints( color : ESkillColor, item : SItemUniqueId ) : int
	{
		var val : SAbilityAttributeValue;
		var colorAttribute : name;
		
		//wrong input
		if( color == SC_None || color == SC_Yellow || !IsIdValid( item ) )
		{
			return 0;
		}
		
		//get attribute name
		switch( color )
		{
			case SC_Red:
				colorAttribute = 'mutation_research_points_red';
				break;
			case SC_Blue:
				colorAttribute = 'mutation_research_points_blue';
				break;
			case SC_Green:
				colorAttribute = 'mutation_research_points_green';
				break;
		}
		
		//get value
		val = GetItemAttributeValue( item, colorAttribute );
		
		return ( int )val.valueAdditive;
	}
	
	public function GetSkillMutagenColor(item : SItemUniqueId) : ESkillColor
	{		
		var abs : array<name>;
	
		//not a mutagen ingredient
		if(!ItemHasTag(item, 'MutagenIngredient'))
			return SC_None;
			
		GetItemAbilities(item, abs);
		
		if(abs.Contains('mutagen_color_green'))			return SC_Green;
		if(abs.Contains('mutagen_color_blue'))			return SC_Blue;
		if(abs.Contains('mutagen_color_red'))			return SC_Red;
		if(abs.Contains('lesser_mutagen_color_green'))	return SC_Green;
		if(abs.Contains('lesser_mutagen_color_blue'))	return SC_Blue;
		if(abs.Contains('lesser_mutagen_color_red'))	return SC_Red;
		if(abs.Contains('greater_mutagen_color_green'))	return SC_Green;
		if(abs.Contains('greater_mutagen_color_blue'))	return SC_Blue;
		if(abs.Contains('greater_mutagen_color_red'))	return SC_Red;
		
		return SC_None;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////   @Enhancements   /////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	// FUNCTIONS YOU ALWAYS WANTED TO KNOW, BUT NOBODY TOLD YOU ABOUT THEM - ITEM SOCKETS 
	//
	import final function GetItemEnhancementSlotsCount( itemId : SItemUniqueId ) : int;
	import final function GetItemEnhancementItems( itemId : SItemUniqueId, out names : array< name > );
	import final function GetItemEnhancementCount( itemId : SItemUniqueId ) : int;
	import final function GetItemColor( itemId : SItemUniqueId ) : name;
	import final function IsItemColored( itemId : SItemUniqueId ) : bool;
	import final function SetPreviewColor( itemId : SItemUniqueId, colorId : int );
	import final function ClearPreviewColor( itemId : SItemUniqueId ) : bool;
	import final function ColorItem( itemId : SItemUniqueId, dyeId : SItemUniqueId );
	import final function ClearItemColor( itemId : SItemUniqueId ) : bool;
	import final function EnchantItem( enhancedItemId : SItemUniqueId, enchantmentName : name, enchantmentStat : name ) : bool;
	import final function GetEnchantment( enhancedItemId : SItemUniqueId ) : name;
	import final function IsItemEnchanted( enhancedItemId : SItemUniqueId ) : bool;
	import final function UnenchantItem( enhancedItemId : SItemUniqueId ) : bool;
	import private function EnhanceItem( enhancedItemId : SItemUniqueId, extensionItemId : SItemUniqueId ) : bool;
	import private function RemoveItemEnhancementByIndex( enhancedItemId : SItemUniqueId, slotIndex : int ) : bool;
	import private function RemoveItemEnhancementByName( enhancedItemId : SItemUniqueId, extensionItemName : name ) : bool;
	import final function PreviewItemAttributeAfterUpgrade( baseItemId : SItemUniqueId, upgradeItemId : SItemUniqueId, attributeName : name, optional baseInventory : CInventoryComponent, optional upgradeInventory : CInventoryComponent ) : SAbilityAttributeValue;
	import final function HasEnhancementItemTag( enhancedItemId : SItemUniqueId, slotIndex : int, tag : name ) : bool;
	
	
	function NotifyEnhancedItem( enhancedItemId : SItemUniqueId )
	{
		var weapons : array<SItemUniqueId>;
		var sword : CWitcherSword;
		var i : int;
		
		sword = (CWitcherSword) GetItemEntityUnsafe( enhancedItemId );
		sword.UpdateEnhancements( this );
	}
	
	function EnhanceItemScript( enhancedItemId : SItemUniqueId, extensionItemId : SItemUniqueId ) : bool
	{
		var i : int;
		var enhancements : array<name>;
		var runeword : Runeword;
		
		if ( EnhanceItem( enhancedItemId, extensionItemId ) )
		{
			NotifyEnhancedItem( enhancedItemId );
			// Check runeword
			GetItemEnhancementItems( enhancedItemId, enhancements );
			if ( theGame.runewordMgr.GetRuneword( enhancements, runeword ) )
			{
				for ( i = 0; i < runeword.abilities.Size(); i+=1 )
				{
					AddItemBaseAbility( enhancedItemId, runeword.abilities[i] );
				}
			}
			return true;
		}
		return false;
	}
	
	function RemoveItemEnhancementByIndexScript( enhancedItemId : SItemUniqueId, slotIndex : int ) : bool
	{
		var i : int;
		var enhancements : array<name>;
		var runeword : Runeword;
		var hasRuneword : bool;
		var names : array< name >;

		GetItemEnhancementItems( enhancedItemId, enhancements );
		hasRuneword = theGame.runewordMgr.GetRuneword( enhancements, runeword );
		
		GetItemEnhancementItems( enhancedItemId, names );
		
		if ( RemoveItemEnhancementByIndex( enhancedItemId, slotIndex ) )
		{
			NotifyEnhancedItem( enhancedItemId );
			
			//Readd rune to inventory
			//AddAnItem( names[slotIndex], 1, true, true );
			if ( hasRuneword )
			{
				//Remove runeword
				for ( i = 0; i < runeword.abilities.Size(); i+=1 )
				{
					RemoveItemBaseAbility( enhancedItemId, runeword.abilities[i] );
				}
			}
			return true;
		}
		return false;
	}
	
	
	function RemoveItemEnhancementByNameScript( enhancedItemId : SItemUniqueId, extensionItemName : name ) : bool
	{
		var i : int;
		var enhancements : array<name>;
		var runeword : Runeword;
		var hasRuneword : bool;

		GetItemEnhancementItems( enhancedItemId, enhancements );
		hasRuneword = theGame.runewordMgr.GetRuneword( enhancements, runeword );
		
		//check runeword
		if ( RemoveItemEnhancementByName( enhancedItemId, extensionItemName ) )
		{
			NotifyEnhancedItem( enhancedItemId );
			
			//Readd rune to inventory
			AddAnItem( extensionItemName, 1, true, true );
			if ( hasRuneword )
			{
				//Remove runeword
				for ( i = 0; i < runeword.abilities.Size(); i+=1 )
				{
					RemoveItemBaseAbility( enhancedItemId, runeword.abilities[i] );
				}
			}
			return true;
		}
		return false;
	}
	
	function RemoveAllItemEnhancements( enhancedItemId : SItemUniqueId )
	{
		var count, i : int;
		
		count = GetItemEnhancementCount( enhancedItemId );
		for ( i = count - 1; i >= 0; i-=1 )
		{
			RemoveItemEnhancementByIndexScript( enhancedItemId, i );
		}
	}
	
	function GetHeldAndMountedItems( out items : array< SItemUniqueId > )
	{
		var allItems : array< SItemUniqueId >;
		var i : int;
		var itemName : name;
	
		GetAllItems( allItems );

		items.Clear();
		for( i = 0; i < allItems.Size(); i += 1 )
		{
			if ( IsItemHeld( allItems[ i ] ) || IsItemMounted( allItems[ i ] ) )
			{
				items.PushBack( allItems[ i ] );
			}
		}
	}
	
	//Check if this inventory components have any valid items for an armor stand, moved here since it's also used in UI popup
	public function GetHasValidDecorationItems( items : array<SItemUniqueId>, decoration : W3HouseDecorationBase ) : bool
	{
		var i, size : int;
		
		size = items.Size();
		
		//No valid items were found in the inventory
		if(size == 0 )
		{
			LogChannel( 'houseDecorations', "No items with valid tag were found!" );
			return false;
		}
		
		//Filter out all items that are not valid but have the tag
		for( i=0; i < size; i+= 1 )
		{	
			//Exclude equipped items
			if( GetWitcherPlayer().IsItemEquipped( items[i] ) )
			{
				LogChannel( 'houseDecorations', "Found item is equipped, erasing..." );
				continue;
			}
			
			//If items m_acceptQuestItems is false exclude all quest items
			if( IsItemQuest( items[i] ) && decoration.GetAcceptQuestItems() == false )
			{
				LogChannel( 'houseDecorations', "Found item is quest item, and quest items are not accepted, erasing..." );
				continue;
			}
			
			//If the item has a forbiden tag
			if( decoration.GetItemHasForbiddenTag( items[i] ) )
			{
				LogChannel( 'houseDecorations', "Found item has a forbidden tag, erasing..." );
				continue;
			}
			
			LogChannel( 'houseDecorations', "Item checks out: "+ GetItemName( items[i] ) );
			return true;
		}
		LogChannel( 'houseDecorations', "No valid items were found!" );
		
		return false;	
	}	
	
	//Checks all defined cards against player's collected cards and Gwent Collector Achievement condition, returns missing cards
	function GetMissingCards() : array< name >
	{
		var defMgr 			: CDefinitionsManagerAccessor 	= theGame.GetDefinitionsManager();
		var allCardNames 	: array< name > 				= defMgr.GetItemsWithTag(theGame.params.GWINT_CARD_ACHIEVEMENT_TAG);
		var playersCards 	: array< SItemUniqueId > 		= GetItemsByTag(theGame.params.GWINT_CARD_ACHIEVEMENT_TAG);
		var playersCardLocs	: array< string >;
		var missingCardLocs	: array< string >;
		var missingCards 	: array< name >;
		var i, j 			: int;
		var found 			: bool;
		
		//divide all cards between found and not found, based on item names (not localization keys)
		for ( i = 0; i < allCardNames.Size(); i+=1 )
		{
			found = false;
			
			for ( j = 0; j < playersCards.Size(); j+=1 )
			{
				if ( allCardNames[i] == GetItemName( playersCards[j] ) )
				{
					found = true;
					playersCardLocs.PushBack( defMgr.GetItemLocalisationKeyName ( allCardNames[i] ) );
					break;
				}
			}
			
			if ( !found )
			{
				missingCardLocs.PushBack( defMgr.GetItemLocalisationKeyName( allCardNames[i] ) );
				missingCards.PushBack( allCardNames[i] );
			}
		}
		
		if( missingCardLocs.Size() < 2 )
		{
			return missingCards;
		}
		
		//remove from missingCards the ones the player's got, based on localization keys so non-achievement cards are also removed
		for ( i = missingCardLocs.Size()-1 ; i >= 0 ; i-=1 )
		{
			for ( j = 0 ; j < playersCardLocs.Size() ; j+=1 )
			{
				if ( missingCardLocs[i] == playersCardLocs[j] 
					&& missingCardLocs[i] != "gwint_name_emhyr" && missingCardLocs[i] != "gwint_name_foltest"
					&& missingCardLocs[i] != "gwint_name_francesca" && missingCardLocs[i] != "gwint_name_eredin" )
				{
					missingCardLocs.EraseFast( i );
					missingCards.EraseFast( i );
					break;
				}
			}
		}
		
		return missingCards;
	}
	
	public function FindCardSources( missingCards : array< name > ) : array< SCardSourceData >
	{
		var sourceCSV 			: C2dArray;
		var sourceTable 		: array< SCardSourceData >;
		var sourceRemaining		: array< SCardSourceData >;
		var sourceCount, i, j	: int;
		
		if ( theGame.IsFinalBuild() )
		{
			sourceCSV = LoadCSV("gameplay\globals\card_sources.csv");
		}
		else
		{
			sourceCSV = LoadCSV("qa\card_sources.csv");
		}

		sourceCount = sourceCSV.GetNumRows();
		sourceTable.Resize(sourceCount);
		
		for ( i = 0 ; i < sourceCount ; i+=1 )
		{
			sourceTable[i].cardName = sourceCSV.GetValueAsName("CardName",i);
			sourceTable[i].source = sourceCSV.GetValue("Source",i);
			sourceTable[i].originArea = sourceCSV.GetValue("OriginArea",i);
			sourceTable[i].originQuest = sourceCSV.GetValue("OriginQuest",i);
			sourceTable[i].details = sourceCSV.GetValue("Details",i);
			sourceTable[i].coords = sourceCSV.GetValue("Coords",i);
		}
		
		for ( i = 0 ; i < missingCards.Size() ; i+=1 )
		{
			for ( j = 0 ; j < sourceCount ; j+=1 )
			{
				if ( sourceTable[j].cardName == missingCards[i] )
				{
					sourceRemaining.PushBack( sourceTable[j] );
				}
			}
		}
		
		return sourceRemaining;
	}
	
	public function GetGwentAlmanacContents() : string
	{
		var sourcesRemaining	: array< SCardSourceData >;
		var missingCards		: array< string >;
		var almanacContents		: string;
		var i 					: int;
		var NML, Novigrad, Skellige, Prologue, Vizima, KaerMorhen, Random : int;

		sourcesRemaining = FindCardSources( GetMissingCards() );
		
		for ( i = 0 ; i < sourcesRemaining.Size() ; i+=1 )
		{
			switch ( sourcesRemaining[i].originArea )
			{
				case "NML":
					NML += 1;
					break;
				case "Novigrad":
					Novigrad += 1;
					break;
				case "Skellige":
					Skellige += 1;
					break;
				case "Prologue":
					Prologue += 1;
					break;
				case "Vizima":
					Vizima += 1;
					break;
				case "KaerMorhen":
					KaerMorhen += 1;
					break;
				case "Random":
					Random += 1;
					break;
				default:
					break;
			}
		}
		
		if ( NML + Novigrad + Skellige + Prologue + Vizima + KaerMorhen + Random == 0 )
		{
			almanacContents = GetLocStringByKeyExt( "gwent_almanac_text" ) + "<br>";
			almanacContents += GetLocStringByKeyExt( "gwent_almanac_completed_text" );
		}
		else
		{
			almanacContents = GetLocStringByKeyExt( "gwent_almanac_text" ) + "<br>";
			if ( NML > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "location_name_velen" ) + ": " + NML + "<br>";
			}
			if ( Novigrad > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "map_location_novigrad" ) + ": " + Novigrad + "<br>";
			}
			if ( Skellige > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "map_location_skellige" ) + ": " + Skellige + "<br>";
			}
			if ( Prologue > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "map_location_prolog_village" ) + ": " + Prologue + "<br>";
			}
			if ( Vizima > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "map_location_wyzima_castle" ) + ": " + Vizima + "<br>";
			}
			if ( KaerMorhen > 0 )
			{
				almanacContents += GetLocStringByKeyExt( "map_location_kaer_morhen" ) + ": " + KaerMorhen + "<br>";
			}
			almanacContents += GetLocStringByKeyExt( "gwent_source_random" ) + ": " + Random;
		}
		
		return almanacContents;
	}
}

exec function findMissingCards( optional card : name )
{
	var inv					: CInventoryComponent = thePlayer.GetInventory();
	var sourcesRemaining	: array< SCardSourceData >;
	var missingCards		: array< name >;
	var i 					: int;
	var sourceLogString		: string;
	
	if ( card != '' )
	{
		missingCards.PushBack( card );
	}
	else
	{
		missingCards = inv.GetMissingCards();
	}
	
	sourcesRemaining = inv.FindCardSources( missingCards );

	for ( i = 0 ; i < sourcesRemaining.Size() ; i+=1 )
	{
		sourceLogString = sourcesRemaining[i].cardName + " is a " + sourcesRemaining[i].source ;
		if ( sourcesRemaining[i].originArea == "Random" )
		{
			sourceLogString += " card from a random merchant.";
		}
		else
		{
			sourceLogString += " item in " + sourcesRemaining[i].originArea + " from ";
			
			if ( sourcesRemaining[i].originQuest != "" )
			{
				sourceLogString += sourcesRemaining[i].originQuest + " , ";
			}
			
			sourceLogString += sourcesRemaining[i].details;
		}
		Log( sourceLogString );
		
		if ( sourcesRemaining[i].coords != "" )
		{
			Log( sourcesRemaining[i].coords ); 
		}
	}
}

exec function slotTest()
{
	var inv : CInventoryComponent = thePlayer.inv;
	var weaponItemId : SItemUniqueId;
	var upgradeItemId : SItemUniqueId;
	var i : int;
	
	LogChannel('SlotTest', "----------------------------------------------------------------");

	// add upgrades
	inv.AddAnItem( 'Perun rune', 1);
	inv.AddAnItem( 'Svarog rune', 1);
	

	for ( i = 0; i < 2; i += 1 )
	{
		// get 'Long Steel Sword'
		if ( !GetItem( inv, 'steelsword', weaponItemId ) ||
			 !GetItem( inv, 'upgrade', upgradeItemId ) )
		{
			return;
		}

		// print
		PrintItem( inv, weaponItemId );
	
		// enhance
		if ( inv.EnhanceItemScript( weaponItemId, upgradeItemId ) )
		{
			LogChannel('SlotTest', "Enhanced item");
		}
		else
		{
			LogChannel('SlotTest', "Failed to enhance item!");
		}
	}
	
	// get item again
	if ( !GetItem( inv, 'steelsword', weaponItemId ) )
	{
		return;
	}

	// print
	PrintItem( inv, weaponItemId );
	
	// remove enhancement by name
	if ( inv.RemoveItemEnhancementByNameScript( weaponItemId, 'Svarog rune' ) )
	{
		LogChannel('SlotTest', "Removed enhancement");
	}
	else
	{
		LogChannel('SlotTest', "Failed to remove enhancement!");
	}

	// get item again
	if ( !GetItem( inv, 'steelsword', weaponItemId ) )
	{
		return;
	}

	// print
	PrintItem( inv, weaponItemId );

	// remove enhancement by index
	if ( inv.RemoveItemEnhancementByIndexScript( weaponItemId, 0 ) )
	{
		LogChannel('SlotTest', "Removed enhancement");
	}
	else
	{
		LogChannel('SlotTest', "Failed to remove enhancement!");
	}
	
	// get item again
	if ( !GetItem( inv, 'steelsword', weaponItemId ) )
	{
		return;
	}

	// print
	PrintItem( inv, weaponItemId );
}

function GetItem( inv : CInventoryComponent, category : name, out itemId : SItemUniqueId ) : bool
{
	var itemIds : array< SItemUniqueId >;

	itemIds = inv.GetItemsByCategory( category );
	if ( itemIds.Size() > 0 )
	{
		itemId = itemIds[ 0 ];
		return true;
	}
	LogChannel( 'SlotTest', "Failed to get item with GetItemsByCategory( '" + category + "' )" );
	return false;
}

function PrintItem( inv : CInventoryComponent, weaponItemId : SItemUniqueId )
{
	var names : array< name >;
	var tags : array< name >;
	var i : int;
	var line : string;
	var attribute : SAbilityAttributeValue;

	LogChannel('SlotTest', "Slots:                         " + inv.GetItemEnhancementCount( weaponItemId ) + "/" + inv.GetItemEnhancementSlotsCount( weaponItemId ) );
	inv.GetItemEnhancementItems( weaponItemId, names );
	if ( names.Size() > 0 )
	{
		for ( i = 0; i < names.Size(); i += 1 )
		{
			if ( i == 0 )
			{
				line += "[";
			}
			line += names[ i ];
			if ( i < names.Size() - 1 )
			{
				line += ", ";
			}
			if ( i == names.Size() - 1 )
			{
				line += "]";
			}
		}
	}
	else
	{
		line += "[]";
	}
	LogChannel('SlotTest', "Upgrade item names             " + line );
	
	tags.PushBack('Upgrade');

	attribute = inv.GetItemAttributeValue( weaponItemId, 'PhysicalDamage' );
	LogChannel('SlotTest', "Attribute '" + 'PhysicalDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );
	attribute = inv.GetItemAttributeValue( weaponItemId, 'SilverDamage' );
	LogChannel('SlotTest', "Attribute '" + 'SilverDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );
	
	attribute = inv.GetItemAttributeValue( weaponItemId, 'PhysicalDamage', tags, true );
	LogChannel('SlotTest', "Attribute '" + 'PhysicalDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );
	attribute = inv.GetItemAttributeValue( weaponItemId, 'SilverDamage', tags, true  );
	LogChannel('SlotTest', "Attribute '" + 'SilverDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );

	attribute = inv.GetItemAttributeValue( weaponItemId, 'PhysicalDamage', tags );
	LogChannel('SlotTest', "Attribute '" + 'PhysicalDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );
	attribute = inv.GetItemAttributeValue( weaponItemId, 'SilverDamage', tags );
	LogChannel('SlotTest', "Attribute '" + 'SilverDamage' + "'      " + attribute.valueBase + " " + attribute.valueMultiplicative + " " + attribute.valueAdditive );

}

function PlayItemEquipSound( itemCategory : name ) : void // #B
{
	switch( itemCategory )
	{
		case 'steelsword' :
			theSound.SoundEvent("gui_inventory_steelsword_attach");
			return;
		case 'silversword' :
			theSound.SoundEvent("gui_inventory_silversword_attach");
			return;
		case 'secondary' :
			theSound.SoundEvent("gui_inventory_weapon_attach");
			return;
		case 'armor' :
			theSound.SoundEvent("gui_inventory_armor_attach");
			return;
		case 'pants' :
			theSound.SoundEvent("gui_inventory_pants_attach");
			return;
		case 'boots' :
			theSound.SoundEvent("gui_inventory_boots_attach");
			return;
		case 'gloves' :
			theSound.SoundEvent("gui_inventory_gauntlet_attach");
			return;
		case 'potion' :
			theSound.SoundEvent("gui_inventory_potion_attach");
			return;
		case 'petard' :
			theSound.SoundEvent("gui_inventory_bombs_attach");
			return;			
		case 'ranged' :
			theSound.SoundEvent("gui_inventory_ranged_attach");
			return;	
		case 'herb' :
			theSound.SoundEvent("gui_pick_up_herbs");
			return;
		case 'trophy' :
		case 'horse_bag' : 
			theSound.SoundEvent("gui_inventory_horse_bage_attach");
			return;
		case 'horse_blinder' :
			theSound.SoundEvent("gui_inventory_horse_blinder_attach");
			return;
		case 'horse_saddle'	: 	
			theSound.SoundEvent("gui_inventory_horse_saddle_attach");
			return;
		default :
			theSound.SoundEvent("gui_inventory_other_attach");
			return;
	}
}

function PlayItemUnequipSound( itemCategory : name ) : void // #B
{	
	switch( itemCategory )
	{
		case 'steelsword' :
			theSound.SoundEvent("gui_inventory_steelsword_back");
			return;
		case 'silversword' :
			theSound.SoundEvent("gui_inventory_silversword_back");
			return;
		case 'secondary' :
			theSound.SoundEvent("gui_inventory_weapon_back");
			return;
		case 'armor' :
			theSound.SoundEvent("gui_inventory_armor_back");
			return;
		case 'pants' :
			theSound.SoundEvent("gui_inventory_pants_back");
			return;
		case 'boots' :
			theSound.SoundEvent("gui_inventory_boots_back");
			return;
		case 'gloves' :
			theSound.SoundEvent("gui_inventory_gauntlet_back");
			return;
		case 'petard' :
			theSound.SoundEvent("gui_inventory_bombs_back");
			return;			
		case 'potion' :
			theSound.SoundEvent("gui_inventory_potion_back");
			return;
		case 'ranged' :
			theSound.SoundEvent("gui_inventory_ranged_back");
			return;
		case 'trophy' :
		case 'horse_bag' : 
			theSound.SoundEvent("gui_inventory_horse_bage_back");
			return;
		case 'horse_blinder' :
			theSound.SoundEvent("gui_inventory_horse_blinder_back");
			return;
		case 'horse_saddle'	: 	
			theSound.SoundEvent("gui_inventory_horse_saddle_back");
			return;
		default :
			theSound.SoundEvent("gui_inventory_other_back");
			return;
	}
}

function PlayItemConsumeSound( item : SItemUniqueId ) : void
{
	if( thePlayer.GetInventory().ItemHasTag( item, 'Drinks' ) || thePlayer.GetInventory().ItemHasTag( item, 'Alcohol' ) )
	{
		theSound.SoundEvent('gui_inventory_drink');
	}
	else
	{
		theSound.SoundEvent('gui_inventory_eat');
	}
}




