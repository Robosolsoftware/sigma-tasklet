tableextension 50300 "Warehouse Activity HeaderExt" extends "Warehouse Activity Header"
{
    fields
    {
        field(50300; "_SourceDocument"; Enum "Warehouse Activity Source Document")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Warehouse Activity Line"."Source Document" where("No." = field("No.")));
        }
    }

    var
        myInt: Integer;


}