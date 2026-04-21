page 50311 "TC Whse Entry Update Dialog"
{
    PageType = StandardDialog;
    Caption = 'Update or Create Warehouse Entry';
    layout
    {
        area(content)
        {
            group(ActionGroup)
            {
                field(ActionType; ActionType)
                {
                    ApplicationArea = All;
                    Caption = 'Action Type';
                }
            }
            group(EntryDetails)
            {
                Visible = (ActionType = ActionType::"Create New Line");
                field(EntryType; EntryType)
                {
                    ApplicationArea = All;
                    Caption = 'Entry Type';
                    Editable = (ActionType = ActionType::"Create New Line");
                }
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = (ActionType = ActionType::"Create New Line");
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                    begin
                        if Page.RunModal(Page::"Item List", Item) = Action::LookupOK then
                            ItemNo := Item."No.";
                    end;
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    Editable = (ActionType = ActionType::"Create New Line");
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                    begin
                        ItemVariant.SetRange("Item No.", ItemNo);
                        if Page.RunModal(Page::"Item Variants", ItemVariant) = Action::LookupOK then
                            VariantCode := ItemVariant.Code;
                    end;
                }
                field(LocationCode; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                    Editable = (ActionType = ActionType::"Create New Line");
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Location: Record Location;
                    begin
                        if Page.RunModal(Page::"Location List", Location) = Action::LookupOK then
                            LocationCode := Location.Code;
                    end;
                }
                field(BinCode; BinCode)
                {
                    ApplicationArea = All;
                    Caption = 'Bin Code';
                    Editable = (ActionType = ActionType::"Create New Line");
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Bin: Record Bin;
                    begin
                        Bin.SetRange("Location Code", LocationCode);
                        if Page.RunModal(Page::"Bin List", Bin) = Action::LookupOK then
                            BinCode := Bin.Code;
                    end;
                }
            }
            group(QuantityGroup)
            {
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                }
            }
        }
    }

    var
        ActionType: Option "Update Quantity","Create New Line";
        EntryType: Option "Positive Adjustment","Negative Adjustment";
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        BinCode: Code[20];
        Quantity: Decimal;
        WhseEntry: Record "Warehouse Entry";

    procedure SetWarehouseEntry(var WhseEnt: Record "Warehouse Entry")
    begin
        WhseEntry := WhseEnt;
    end;

    procedure GetActionType(): Integer
    begin
        exit(ActionType);
    end;

    procedure GetEntryType(): Integer
    begin
        exit(EntryType);
    end;

    procedure GetItemNo(): Code[20]
    begin
        exit(ItemNo);
    end;

    procedure GetLocationCode(): Code[10]
    begin
        exit(LocationCode);
    end;

    procedure GetBinCode(): Code[20]
    begin
        exit(BinCode);
    end;

    procedure GetQuantity(): Decimal
    begin
        exit(Quantity);
    end;

    procedure GetVariantCode(): Code[10]
    begin
        exit(VariantCode);
    end;
}