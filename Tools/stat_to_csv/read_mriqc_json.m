function Ta = read_mriqc_json(fmr)


tic
for ns=1:length(fmr)
    j=spm_jsonread(fmr{ns});
    meta=j.bids_meta.global.const;
    j = rmfield(j,{'bids_meta','provenance'});
    T=struct2table(j);
    fname=fieldnames(meta);
    fnameT = addprefixtofilenames(fname,'meta_');
    for ii =1:length( fname)
        if ~startsWith(fname{ii},{'Csa','DateOfLastCalibration'})
            val = meta.(fname{ii});
            if iscell(val)
                if isstruct(val{1})
                    continue;
                end
                if isnumeric(val{1})
                    val=cell2mat(val)';
                elseif isstring(val{1})|ischar(val{1})
                    aa=val{1};
                    for kk=2:numel(val), aa=[aa '_' val{kk}];end;
                    val=string(aa);
                else
                    fprintf('skiping %s \n',fname{ii});meta.(fname{ii});
                end
            end
            if ischar(val); val=string(val);end %for good concatenation of table
            T.(fnameT{ii}) = val;
        end
    end
    if ns==1
        Ta=T;
    else
        Tcolmissing = setdiff(Ta.Properties.VariableNames, T.Properties.VariableNames);
        Tacolmissing = setdiff(T.Properties.VariableNames, Ta.Properties.VariableNames);
        if ~isempty(Tcolmissing),T = [T array2table(nan(height(T), numel(Tcolmissing)), 'VariableNames', Tcolmissing)];end
        if ~isempty(Tacolmissing), Ta = [Ta array2table(nan(height(Ta), numel(Tacolmissing)), 'VariableNames', Tacolmissing)];
            fprintf('adding col %s for %s\n',char(Tacolmissing),fmr{ns}); Tacolmissing
        end
        Ta = [Ta; T];
    end
end
toc

[~, prot, sujn, ser, ~, ~, ~, ~, ~] = get_parent_path(fmr,8);
sid = concat_cell_str(prot,sujn,ser);
Ta.sujid = sid;

removevars = {'PatientComments','PhysiciansOfRecord','ImageComments','AccessionNumber','ContrastBolusVolume','ContrastBolusTotalDose',...
    'ContrastBolusIngredientConcentration','ContrastBolusAgent','TimeOfLastCalibration','ReferringPhysicianName','RequestingPhysician',...
    'AngioFlag','BitsAllocated','BitsStored','BodyPartExamined','InstitutionAddress','InstitutionalDepartmentName','MagneticFieldStrength',...
    'Manufacturer','Modality','PatientID','PixelRepresentation','SOPClassUID','PerformedProcedureStepDescription','SmallestImagePixelValue',...
    'SpecificCharacterSet','RescaleIntercept','RescaleSlope','RescaleType','WindowCenter','WindowWidth','PerformingPhysicianName'};
removevars = addprefixtofilenames(removevars,'meta_');

for ii = 1:length(removevars)
    Ta.(removevars{ii})	=[];
end

