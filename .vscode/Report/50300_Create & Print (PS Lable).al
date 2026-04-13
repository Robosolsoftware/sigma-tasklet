report 50300 "Create & Print (PS Lable)"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            trigger OnAfterGetRecord()
            var
                PSChanges: Codeunit "Polar Speed Changes";
            begin
                PSChanges.Manual_CreateEentryInPSdetailstable(G_Barcode, G_ToteSequence, G_OrderCategory);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Filters: ")
                {
                    field(G_OrderCategory; G_OrderCategory)
                    {
                        ApplicationArea = All;
                        Caption = 'Select Order Category: ';
                    }
                    field(G_Barcode; G_Barcode)
                    {
                        ApplicationArea = All;
                        Caption = 'Enter Barcode: ';
                    }
                    field(G_ToteSequence; G_ToteSequence)
                    {
                        ApplicationArea = All;
                        Caption = 'Tote Sequence: ';
                        Editable = G_OrderCategory = G_OrderCategory::Knapp;
                    }

                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = CloseAction::OK then begin
                if G_OrderCategory = G_OrderCategory::" " then
                    Error('Order Category should not be blank');

                if G_Barcode = '' then
                    Error('Barcode should not be blank');
            end;
        end;
    }

    var
        myInt: Integer;
        G_OrderCategory: Option " ",Manual,Knapp;
        G_Barcode: Code[50];
        G_ToteSequence: Integer;
}