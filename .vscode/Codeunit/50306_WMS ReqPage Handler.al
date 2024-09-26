codeunit 50306 "WMS ReqPage Handler"
{
    Permissions = tabledata 110 = m;
    //We dont required to print KNAAP Invoice from Scanner+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
        ItemNo: Text;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Sales Invoice (Order)" then
            exit;
        _Steps.Create_TextStep(10, 'ToteNo');
        _Steps.Set_header('Tote No');
        _Steps.Set_label('Tote No:');

        _Steps.Create_TextStep(20, 'NoOfCopies');
        _Steps.Set_header('No Of Copies');
        _Steps.Set_label('No Of Copies:');
        _Steps.Set_defaultValue(1);
        _Steps.Set_minValue(1);

        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, 90, 0);
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParameters(_MobReport: Record "Mob Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        L_GetNoofCopy: Integer;
        L_SetNoofCopy: Integer;
        L_SalesLine: Record "Sales Line";
    begin
        Clear(L_GetNoofCopy);
        Clear(L_SetNoofCopy);
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Sales Invoice (Order)" then
            exit;

        L_SalesLine.Reset();
        L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
        L_SalesLine.SetRange("Load Unit", _RequestValues.GetValue('ToteNo'));
        if L_SalesLine.FindFirst() then begin
            SalesHeader.Reset();
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
            SalesHeader.SetRange("No.", L_SalesLine."Document No.");
            //SalesHeader.SetRange("No.", _RequestValues.GetValue('SalesOrderNo'));
            if SalesHeader.FindFirst() then begin
                _DataItemViews.SetValue('Sales Header', SalesHeader.GetView(false));
                Evaluate(L_GetNoofCopy, _RequestValues.GetValue('NoOfCopies'));
                if L_GetNoofCopy = 1 then
                    L_SetNoofCopy := 0
                else
                    L_SetNoofCopy := L_GetNoofCopy;
                _OptionsFieldValues.SetValue('NoOfCopies', L_SetNoofCopy);
            end;
        end;



        _IsHandled := true;
    end;
    //We dont required to print KNAAP Invoice from Scanner+++

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReportInvoice(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
        ItemNo: Text;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Sales Invoice" then
            exit;
        _Steps.Create_TextStep(10, 'InvPickNo');
        _Steps.Set_header('Inventory Pick No.');
        _Steps.Set_label('Inventory Pick No.:');

        _Steps.Create_IntegerStep(20, 'NoOfCopies');
        _Steps.Set_header('No Of Copies');
        _Steps.Set_label('No Of Copies:');
        _Steps.Set_defaultValue(1);
        _Steps.Set_minValue(1);

        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, 90, 0);
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParametersInvoice(_MobReport: Record "Mob Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        L_GetNoofCopy: Integer;
        L_SetNoofCopy: Integer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Clear(L_GetNoofCopy);
        Clear(L_SetNoofCopy);
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Sales Invoice" then
            exit;

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetRange("Inv. Pick No.", _RequestValues.GetValue('InvPickNo'));
        if SalesInvoiceHeader.FindSet() then begin
            _DataItemViews.SetValue('Sales Invoice Header', SalesInvoiceHeader.GetView(false));
            Evaluate(L_GetNoofCopy, _RequestValues.GetValue('NoOfCopies'));
            if L_GetNoofCopy = 1 then
                L_SetNoofCopy := 0
            else
                L_SetNoofCopy := L_GetNoofCopy - 1;
            _OptionsFieldValues.SetValue('NoOfCopies', L_SetNoofCopy);
        end else
            Error('Sales Invoice does not exist for order: %1', _RequestValues.GetValue('InvPickNo'));
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReportLabel(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
        ItemNo: Text;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::ShipmentLabel then
            exit;

        _Steps.Create_TextStep(10, 'InvPickNo');
        _Steps.Set_header('Inventory Pick No.');
        _Steps.Set_label('Inventory Pick No.:');

        _Steps.Create_IntegerStep(20, 'NoOfCopies');
        _Steps.Set_header('No Of Copies');
        _Steps.Set_label('No Of Copies:');
        _Steps.Set_defaultValue(1);
        _Steps.Set_minValue(1);

        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, 90, 0);
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParametersLabel(_MobReport: Record "Mob Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        L_SalesShipmentHeader: Record "Sales Shipment Header";
        Item: Record Item;
        L_GetNoofCopy: Integer;
        L_SetNoofCopy: Integer;
    begin
        Clear(L_GetNoofCopy);
        Clear(L_SetNoofCopy);
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::ShipmentLabel then
            exit;

        //Update No Of Box++
        L_SalesShipmentHeader.Reset();
        L_SalesShipmentHeader.SetRange("Inv. Pick No.", _RequestValues.GetValue('InvPickNo'));
        L_SalesShipmentHeader.SetFilter("No of Boxes", '>%1', 0); //If No. of Box Already updated then only Print label++
        if not L_SalesShipmentHeader.FindFirst() then begin
            L_SalesShipmentHeader.Reset();
            L_SalesShipmentHeader.SetRange("Inv. Pick No.", _RequestValues.GetValue('InvPickNo'));
            if L_SalesShipmentHeader.FindFirst() then begin
                Clear(L_GetNoofCopy);
                //Evaluate(L_GetNoofCopy, _RequestValues.GetValue('NoOfCopies'));
                L_GetNoofCopy := _RequestValues.GetValueAsInteger('NoOfCopies');
                L_SalesShipmentHeader."No of Boxes" := L_GetNoofCopy;
                L_SalesShipmentHeader.Modify();
            end;
        end;



        //Print Label++
        L_SalesShipmentHeader.Reset();
        L_SalesShipmentHeader.SetRange("Inv. Pick No.", _RequestValues.GetValue('InvPickNo'));
        if L_SalesShipmentHeader.FindFirst() then begin
            _DataItemViews.SetValue('Sales Shipment Header', L_SalesShipmentHeader.GetView(false));
            Evaluate(L_GetNoofCopy, _RequestValues.GetValue('NoOfCopies'));
            if L_GetNoofCopy = 1 then
                L_SetNoofCopy := 0
            else
                L_SetNoofCopy := L_GetNoofCopy - 1;
            _OptionsFieldValues.SetValue('NoOfCopies', L_SetNoofCopy);
        end else
            Error('Label does not exist for Order: %1', _RequestValues.GetValue('InvPickNo'));

        _IsHandled := true;
    end;


    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnAfterPostAnyOrder', '', true, true)]
    local procedure OnPostPickOrder_OnAfterPostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef; var _ResultMessage: Text)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        MOBReport: Record "MOB Report";
        MobPrinter: Record "MOB Printer";
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        MobPrint: Codeunit "MOB Print";
        MobPrintBuffer: Codeunit "MOB Print Buffer";
        MOBReportPrinterReport: Record "MOB Report Printer Report";
        PrintCommand: Text;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        L_RecRef: RecordRef;
        Label: Report Label;
    begin
        if (_RecRef.Number() in [DataBase::"Warehouse Activity Line"]) then begin
            _RecRef.SetTable(WarehouseActivityLine);
            if WarehouseActivityLine."Activity Type" = WarehouseActivityLine."Activity Type"::"Invt. Pick" then begin
                SalesHeader.Reset();
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("No.", WarehouseActivityLine."Source No.");
                if SalesHeader.FindFirst() then begin
                    L_RecRef.getTable(SalesHeader);
                    MOBReport.Reset();
                    MOBReport.SetRange(Enabled, true);
                    if MOBReport.FindSet() then
                        repeat
                            MOBReportPrinterReport.Reset();
                            MOBReportPrinterReport.SetRange("Report Display Name", MOBReport."Display Name");
                            if MOBReportPrinterReport.FindFirst() then begin
                                report.Print(MOBReport."Report ID", '', MOBReportPrinterReport."Printer Name", L_RecRef);
                                // Evaluate(TempPrintParameter.Printer, MOBReportPrinterReport."Printer Name");
                                // TempPrintParameter."Label-Template Name" := MOBReport."Display Name";
                                // MobPrint.SetSourceRecRef(L_RecRef);
                                // MobPrint.SetRequestElementsFromOrderValues(_OrderValues);
                                // if MobPrint.Run(TempPrintParameter) then begin
                                //     TempPrintParameter.GetResponseContentAsBase64Text(PrintCommand);
                                //     MobPrint.GetPrinterFromName(MobPrinter, TempPrintParameter.Printer);
                                //     MobPrintBuffer.Add(MobPrinter.Address, PrintCommand);
                                // end else
                                //     _ResultMessage := _ResultMessage + ' Print failed: ' + GetLastErrorText();
                            end;

                        until MOBReport.Next() = 0;
                end;
            end;
            Error('');
        end;
    end;*/

    #Region Commented +++++
    //Abdul:- I have Commented this code to update No of Box on sales header at the time of posting Inve Pick. Because they dont want to print any report at the time of posting InV pick.+++
    // If in future they want we can use the below code++++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnAfterPostWhseActivHeader', '', true, true)]
    // local procedure OnAfterPostWhseActivHeader(var SalesHeader: Record "Sales Header"; WhseActivHeader: Record "Warehouse Activity Header")
    // var
    //     L_RecRef: RecordRef;
    //     MOBReport: Record "MOB Report";
    //     MOBReportPrinterReport: Record "MOB Report Printer Report";
    //     Report60039: report Label;
    //     //Report60040: report "Sales Invoice (Order)";
    //     //Rep60040: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Sales Invoice (Order)" id="60040"><Options><Field name="NoOfCopies">0</Field></Options><DataItems><DataItem name="Sales Header">VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(1),Field3=1(%1))</DataItem><DataItem name="CopyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="PageLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Sales Line">VERSION(1) SORTING(Field1,Field3,Field4)</DataItem><DataItem name="RoundLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Integer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="VATCounter">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
    //     Rep60039: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Label" id="60039"><Options><Field name="NoOfCopies">%1</Field></Options><DataItems><DataItem name="Sales Header">VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(1),Field3=1(%2))</DataItem><DataItem name="CopyLoop">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
    //     L_SalesHeader: Record "Sales Header";
    //     L_SetNoofCopy: Integer;
    // begin
    //     if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
    //         L_RecRef.getTable(SalesHeader);
    //         MOBReport.Reset();
    //         MOBReport.SetRange(Enabled, true);
    //         if MOBReport.FindSet() then
    //             repeat
    //                 if MOBReport."Auto Print" = true then begin
    //                     MOBReportPrinterReport.Reset();
    //                     MOBReportPrinterReport.SetRange("Report Display Name", MOBReport."Display Name");
    //                     if MOBReportPrinterReport.FindFirst() then begin
    //                         if MOBReport."Report ID" = 60039 then begin
    //                             Clear(L_SetNoofCopy);
    //                             if SalesHeader."No of Boxes" = 1 then
    //                                 L_SetNoofCopy := 0
    //                             else
    //                                 L_SetNoofCopy := SalesHeader."No of Boxes" - 1;
    //                             Report60039.Print(StrSubstNo(Rep60039, L_SetNoofCopy, SalesHeader."No."), MOBReportPrinterReport."Printer Name");
    //                         end;
    //                     end;
    //                 end;
    //             until MOBReport.Next() = 0;
    //     end;
    // end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnAddStepsToAnyHeader', '', true, true)]
    // local procedure OnPostPickOrder_OnAddStepsToAnyHeader(var _OrderValues: Record "MOB Common Element"; _RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    // begin
    //     if _RecRef.Number() in [Database::"Warehouse Activity Header", Database::"Sales Header"] then begin
    //         if _OrderValues.HasValue('NoofBoxes') then
    //             exit;

    //         _StepsElement.Create_IntegerStep(10000, 'NoofBoxes');
    //         _StepsElement.Set_header('No. of Boxes');
    //         _StepsElement.Set_label('No. of Boxes:');
    //         _StepsElement.Set_defaultValue(1);
    //         _StepsElement.Set_minValue(1);
    //     end;
    // end;


    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforePostSalesOrder', '', true, true)]
    // local procedure OnPostPickOrder_OnBeforePostSalesOrder(var _OrderValues: Record "MOB Common Element"; var _SalesHeader: Record "Sales Header")
    // var
    //     NoofBoxes: Integer;
    // begin
    //     if _OrderValues.GetValue('NoofBoxes') <> '' then begin
    //         Evaluate(NoofBoxes, _OrderValues.GetValue('NoofBoxes'));
    //         _SalesHeader."No of Boxes" := NoofBoxes;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforePostWarehouseActivityOrder', '', true, true)]
    // local procedure OnPostPickOrder_OnBeforePostWarehouseActivityOrder(var _OrderValues: Record "MOB Common Element"; var _WhseActivityHeader: Record "Warehouse Activity Header")
    // var
    //     NoofBoxes: Integer;
    //     WarehouseActivityLine: Record "Warehouse Activity Line";
    //     SalesHeader: Record "Sales Header";
    // begin
    //     if _OrderValues.GetValue('NoofBoxes') <> '' then begin
    //         Evaluate(NoofBoxes, _OrderValues.GetValue('NoofBoxes'));
    //         if _WhseActivityHeader.Type = _WhseActivityHeader.Type::"Invt. Pick" then begin
    //             WarehouseActivityLine.Reset();
    //             WarehouseActivityLine.SetRange("Activity Type", _WhseActivityHeader.Type);
    //             WarehouseActivityLine.SetRange("No.", _WhseActivityHeader."No.");
    //             WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Sales Order");
    //             if WarehouseActivityLine.FindSet() then
    //                 repeat
    //                     SalesHeader.Reset();
    //                     SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
    //                     SalesHeader.SetRange("No.", WarehouseActivityLine."Source No.");
    //                     if SalesHeader.FindFirst() then begin
    //                         SalesHeader.Validate("No of Boxes", NoofBoxes);
    //                         SalesHeader.Modify();
    //                     end;
    //                 until WarehouseActivityLine.Next() = 0;
    //         end;
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', true, true)]
    // local procedure OnAfterPostSalesDoc(SalesInvHdrNo: Code[20])
    // var
    //     Report60044: report "Sales - Invoice Copy";
    //     MOBReport: Record "MOB Report";
    //     MOBReportPrinterReport: Record "MOB Report Printer Report";
    //     SalesInvoiceHeader: Record "Sales Invoice Header";
    //     Rep60034: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="SalesInvoice SI" id="60044"><Options><Field name="NoOfCopies">%1</Field><Field name="ShowInternalInfo">false</Field><Field name="ArchiveDocument">false</Field><Field name="LogInteraction">false</Field><Field name="CurrencyLCY">false</Field></Options><DataItems><DataItem name="Sales Invoice Header">VERSION(1) SORTING(Field3) WHERE(Field3=1(%2))</DataItem><DataItem name="CopyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="PageLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DimensionLoop1">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Sales Invoice Line">VERSION(1) SORTING(Field3,Field4)</DataItem><DataItem name="Sales Shipment Buffer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DimensionLoop2">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Integer">VERSION(1) SORTING(Field1)</DataItem><DataItem name="VATCounter">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Total">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Integer2">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Total2">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>';
    // begin
    //     SalesInvoiceHeader.Reset();
    //     SalesInvoiceHeader.SetRange("No.", SalesInvHdrNo);
    //     if SalesInvoiceHeader.FindFirst() then begin
    //         MOBReport.Reset();
    //         MOBReport.SetRange(Enabled, true);
    //         if MOBReport.FindSet() then
    //             repeat
    //                 if MOBReport."Auto Print" = true then begin
    //                     MOBReportPrinterReport.Reset();
    //                     MOBReportPrinterReport.SetRange("Report Display Name", MOBReport."Display Name");
    //                     if MOBReportPrinterReport.FindFirst() then begin
    //                         if MOBReport."Report ID" = 60044 then
    //                             Report60044.Print(StrSubstNo(Rep60034, 0, SalesInvoiceHeader."No."), MOBReportPrinterReport."Printer Name"); //SalesInvoiceHeader."No of Boxes"
    //                     end;
    //                 end;
    //             until MOBReport.Next() = 0;
    //     end;
    // end;
    #endregion Commented+++++

}

