codeunit 50303 "Clear Knapp Doc Queue List"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin
        case rec."Parameter String" of
            'ClearKnappDocQueueList':
                ClearKnappDocQueueList();
            'ClearMobileDocQueueList':
                ClearMobileDocQueueList();

        end;
    end;

    local procedure ClearKnappDocQueueList()
    var
        RecGenSetupChannels: record "Sales & Receivables Setup";
        RecKnappDocQueue: record "Knapp Document Queue";
    begin
        if RecGenSetupChannels.get then RecGenSetupChannels.TestField("Knapp Doc Queue DateFilter");
        RecKnappDocQueue.SetFilter("Document Type", '%1 | %2', RecKnappDocQueue."Document Type"::Order, RecKnappDocQueue."Document Type"::"Order Update");
        RecKnappDocQueue.SetFilter(SystemCreatedAt, '<%1', CreateDateTime(CalcDate(RecGenSetupChannels."Knapp Doc Queue DateFilter", WorkDate()), 0T));
        if RecKnappDocQueue.FindSet() then RecKnappDocQueue.DeleteAll();
    end;

    local procedure ClearMobileDocQueueList()
    var
        RecGenSetupChannels: record "Sales & Receivables Setup";
        RecMOBDocQueue: record "MOB Document Queue";
    begin
        if RecGenSetupChannels.get then RecGenSetupChannels.TestField("Mobile Doc Queue DateFilter");
        RecMOBDocQueue.SetFilter(SystemCreatedAt, '<%1', CreateDateTime(CalcDate(RecGenSetupChannels."Mobile Doc Queue DateFilter", WorkDate()), 0T));
        if RecMOBDocQueue.FindSet() then RecMOBDocQueue.DeleteAll();
    end;
}
