pageextension 50305 "TC Phys. Inventory Journal" extends "Phys. Inventory Journal"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field(SystemModifiedBy; GetUserName(Rec.SystemModifiedBy))
            {
                ApplicationArea = all;
                Editable = false;
                Caption = 'Modified By';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
        G_MiscellaneousCharges: Codeunit "Miscellaneous Charges";

    procedure GetUserName(UserSecurityId: Code[50]): Text[100]
    var
        Users: Record User;
    begin
        Users.Reset();
        Users.SetRange("User Security ID", UserSecurityId);
        if Users.FindFirst() then
            exit(Users."User Name");
    end;


}