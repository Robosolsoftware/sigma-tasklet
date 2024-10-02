codeunit 50307 "Post Inv Pick & Invoice"
{
    SingleInstance = true;
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        G_Ship: Boolean;
        G_ShipAndInvoice: Text;

    // ///////////////////////////////////////////////////Not Require Option//////////////////////////////////////////////////////////////////////
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnAddStepsToWarehouseActivityHeader', '', false, false)]
    // local procedure OnPostPickOrder_OnAddStepsToWarehouseActivityHeader(_WhseActivityHeader: Record "Warehouse Activity Header"; var _OrderValues: Record "MOB Common Element"; var _StepsElement: Record "MOB Steps Element")
    // begin
    //     // Break if new datestep is already collected to prevent infinite loop
    //     if _OrderValues.HasValue('SI') then
    //         exit;

    //     case _WhseActivityHeader.Type of
    //         _WhseActivityHeader.Type::"Invt. Pick":
    //             begin
    //                 Clear(G_Ship);
    //                 Clear(G_ShipAndInvoice);
    //                 _StepsElement.Create_RadioButtonStep(50000, 'SI', 'Post Invt. Pick', '', '', '', 'Ship;Ship and Invoice');
    //             end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforePostWarehouseActivityOrder', '', false, false)]
    // local procedure OnPostPickOrder_OnBeforePostWarehouseActivityOrder(var _WhseActivityHeader: Record "Warehouse Activity Header"; var _OrderValues: Record "MOB Common Element")
    // begin
    //     case _WhseActivityHeader.Type of
    //         _WhseActivityHeader.Type::"Invt. Pick":
    //             begin
    //                 Clear(G_Ship);
    //                 Clear(G_ShipAndInvoice);
    //                 IF _OrderValues.GetValue('SI', true) <> '' THEN begin
    //                     Evaluate(G_ShipAndInvoice, _OrderValues.GetValue('SI', true));
    //                 end;
    //             end;
    //     end;
    // end;



    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforeRunWhseActivityPost', '', false, false)]
    // local procedure OnPostPickOrder_OnBeforeRunWhseActivityPost(var _WhseActPost: Codeunit "Whse.-Activity-Post")
    // begin
    //     //Set to Post Invoice Also++
    //     if UpperCase(G_ShipAndInvoice) = UpperCase('Ship and Invoice') then
    //         _WhseActPost.SetInvoiceSourceDoc(true);
    // end;
    // ///////////////////////////////////////////////////Not Require Option//////////////////////////////////////////////////////////////////////



    //Not Require Option - 02/10/2024+++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforeRunWhseActivityPost', '', false, false)]
    // local procedure OnPostPickOrder_OnBeforeRunWhseActivityPost(var _WhseActPost: Codeunit "Whse.-Activity-Post")
    // begin
    //     //Set to Post Invoice Also++
    //     _WhseActPost.SetInvoiceSourceDoc(true);
    // end;
    //Not Require Option - 02/10/2024---
}