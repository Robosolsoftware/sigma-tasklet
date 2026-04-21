page 50310 "TC Update/Create Qty Dialog"
{
    PageType = StandardDialog;
    Caption = 'Update or Create Quantity';
    layout
    {
        area(content)
        {
            group(Group)
            {
                field(ActionOption; ActionOption)
                {
                    ApplicationArea = All;
                    Caption = 'Action';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                }
            }
        }
    }
    var
        ActionOption: Option "Update Quantity","Create New Line";
        Quantity: Decimal;
        ItemLedgerEntry: Record "Item Ledger Entry";

    procedure SetItemLedgerEntry(var ILE: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry := ILE;
    end;

    procedure GetActionOption(): Integer
    begin
        exit(ActionOption);
    end;

    procedure GetQuantity(): Decimal
    begin
        exit(Quantity);
    end;
}