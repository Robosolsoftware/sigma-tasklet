codeunit 50312 "TC ILE Qty Handler2"
{
    Permissions = TableData "Item Ledger Entry" = M;
    procedure HandleAction(var ILE: Record "Item Ledger Entry"; ActionOption: Integer; Qty: Decimal)
    begin
        case ActionOption of
            0: // Update Quantity
                UpdateRemainingQty(ILE, Qty);
            1: // Create New Line
                CreateNewLine(ILE, Qty);
        end;
    end;

    local procedure UpdateRemainingQty(var ILE: Record "Item Ledger Entry"; Qty: Decimal)
    begin
        ILE.Validate("Remaining Quantity", Qty);
        ILE.Modify(true);
    end;

    local procedure CreateNewLine(var ILE: Record "Item Ledger Entry"; Qty: Decimal)
    var
        NewILE: Record "Item Ledger Entry";
    begin
        // Clear(NewILE);
        // NewILE.Init();
        // // Set required fields for a new Item Ledger Entry here
        // // Example: NewILE.Validate("Item No.", ''); // Set as needed
        // NewILE."Remaining Quantity" := Qty;
        // // Set other mandatory fields as per your business logic
        // NewILE.Insert(true);
    end;
}