tableextension 50303 "Warehouse recp HeaderExt" extends "Warehouse Receipt Header"
{
    fields
    {
        field(50300; "_SourceDocument"; Enum "Warehouse Activity Source Document")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Warehouse Receipt Line"."Source Document" where("No." = field("No.")));
        }
        field(50301; "Curtain Side Vehicle"; Boolean)
        {

        }
        field(50302; "Data Logger Received"; Boolean)
        {

        }
    }

    var
        myInt: Integer;


}