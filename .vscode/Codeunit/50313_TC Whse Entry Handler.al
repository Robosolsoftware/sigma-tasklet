codeunit 50313 "TC Whse Entry Handler"
{
    Permissions = TableData "Warehouse Entry" = MI;

    procedure HandleAction(var WhseEntry: Record "Warehouse Entry"; ActionType: Integer; EntryType: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    begin
        case ActionType of
            0: // Update Quantity
                UpdateQuantity(WhseEntry, Qty);
            1: // Create New Line
                CreateNewLine(WhseEntry, EntryType, ItemNo, VariantCode, LocationCode, BinCode, Qty);
        end;
    end;

    local procedure UpdateQuantity(var WhseEntry: Record "Warehouse Entry"; Qty: Decimal)
    begin
        WhseEntry.Validate(Quantity, Qty);
        WhseEntry.Modify(true);
    end;

    local procedure CreateNewLine(var SourceWhseEntry: Record "Warehouse Entry"; EntryType: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        NewWhseEntry: Record "Warehouse Entry";
        EntryNoCounter: Integer;
    begin
        Clear(NewWhseEntry);
        NewWhseEntry.Init();

        // Get the next entry number
        if NewWhseEntry.FindLast() then
            EntryNoCounter := NewWhseEntry."Entry No." + 1
        else
            EntryNoCounter := 1;

        NewWhseEntry."Entry No." := EntryNoCounter;
        NewWhseEntry.Validate("Item No.", ItemNo);
        NewWhseEntry.Validate("Variant Code", VariantCode);
        NewWhseEntry.Validate("Location Code", LocationCode);
        NewWhseEntry.Validate("Bin Code", BinCode);

        // Set Entry Type based on user selection
        case EntryType of
            0: // Positive Adjustment
                NewWhseEntry."Entry Type" := NewWhseEntry."Entry Type"::"Positive Adjmt.";
            1: // Negative Adjustment
                NewWhseEntry."Entry Type" := NewWhseEntry."Entry Type"::"Negative Adjmt.";
        end;

        NewWhseEntry.Validate(Quantity, Qty);
        NewWhseEntry."Registering Date" := Today();
        NewWhseEntry."User ID" := UserId();
        NewWhseEntry."Whse. Document Type" := NewWhseEntry."Whse. Document Type"::" ";
        NewWhseEntry."Whse. Document No." := '';
        NewWhseEntry."Whse. Document Line No." := 0;
        NewWhseEntry."Reference Document" := NewWhseEntry."Reference Document"::" ";
        NewWhseEntry."Source Document" := NewWhseEntry."Source Document"::"S. Order";
        NewWhseEntry."Source Code" := '';
        NewWhseEntry."Source No." := '';
        NewWhseEntry."Source Type" := 0;
        NewWhseEntry."Source Subtype" := 0;
        NewWhseEntry.Description := 'This is for adjustment from Robosol';
        NewWhseEntry.Insert(true);
    end;
}
