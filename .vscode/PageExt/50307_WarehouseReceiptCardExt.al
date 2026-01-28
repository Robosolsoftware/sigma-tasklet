pageextension 50307 WarehouseReceiptCardEXT extends "Warehouse Receipt"
{
    layout
    {
        addafter("Fridge Qty.")
        {
            field("Curtain Side Vehicle"; Rec."Curtain Side Vehicle")
            {
                ApplicationArea = all;
            }
            field("Data Logger Received"; Rec."Data Logger Received")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}