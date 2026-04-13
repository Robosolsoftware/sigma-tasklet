pageextension 50309 "TC PS Label Details" extends "PS Label Details"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Upload Manifest File")
        {
            action("Create & Print PS Lable (Manual)")
            {
                ApplicationArea = All;
                Image = Create;
                Visible = false;

                trigger OnAction()
                var
                    "Create & Print (PS Lable)": Report "Create & Print (PS Lable)";
                begin
                    "Create & Print (PS Lable)".Run();
                end;
            }
        }
    }

    var
        myInt: Integer;
}