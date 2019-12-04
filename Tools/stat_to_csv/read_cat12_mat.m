function [cout, dir_missing] = read_cat12_mat(fin)
%fin list of


mark2rps = @(mark) min(100,max(0,105 - mark*10));

load(fin{1})

%init
if isfield(S,'qualitymeasures')
    
    cfield = {'meanB','meanC','meanG','meanW','stdB','stdC','stdG','stdW','contrast','contrastr',...
        'NCR','ICR','qr_noise','qr_bias','IQR','vol_C','vol_G','vol_W','vol_WH','sr_TIV','SQR'}
    vinit = ones(size(fin))*NaN; for kk =1:length(cfield), cout.(cfield{kk})=vinit;end
end
dir_missing={};

for k=1:length(fin)
    try 
        load(fin{k})
    catch 
        fprintf('corupt %s\n',fin{k})
        dir_missing(end+1) = fin{k};
        continue
        
    end
    
    found=0;
    
    if isfield(S,'qualitymeasures')
        cout.suj{k} = fin{k};
        cout.meanB(k) = S.qualitymeasures.tissue_mn(1);cout.meanC(k) = S.qualitymeasures.tissue_mn(2);
        cout.meanG(k) = S.qualitymeasures.tissue_mn(3);cout.meanW(k) = S.qualitymeasures.tissue_mn(4);
        cout.stdB(k) = S.qualitymeasures.tissue_std(1);cout.stdC(k) = S.qualitymeasures.tissue_std(2);
        cout.stdG(k) = S.qualitymeasures.tissue_std(3);cout.stdW(k) = S.qualitymeasures.tissue_std(4);
        cout.contrast(k) = S.qualitymeasures.contrast; cout.contrastr(k) = S.qualitymeasures.contrastr;
        cout.NCR(k) = S.qualitymeasures.NCR;cout.ICR(k) = S.qualitymeasures.ICR;
        
        cout.qr_noise(k) = mark2rps(S.qualityratings.NCR);
        cout.qr_bias(k)  = mark2rps(S.qualityratings.ICR);
        cout.IQR(k)      = mark2rps(S.qualityratings.IQR);
        
        cout.vol_C(k) = S.subjectmeasures.vol_abs_CGW(1);cout.vol_G(k) = S.subjectmeasures.vol_abs_CGW(2);
        cout.vol_W(k) = S.subjectmeasures.vol_abs_CGW(3);cout.vol_WH(k) = S.subjectmeasures.vol_abs_CGW(4);
        cout.sr_TIV(k) = S.subjectratings.vol_TIV; cout.SQR(k) = S.subjectratings.SQR;
        
        found=1;
    end
    if isfield(S,'lpba40')
        
        colname = S.lpba40.names; colname = strrep(colname,'+','_');
        for kk=1:length(colname)
            cout.([ 'ba40_' colname{kk} '_gm'])(k) = S.lpba40.data.Vgm(kk);
        end
        
        found=1;
    end
    
    if isfield(S,'hammers')
        
        colname = S.hammers.names;  colname = strrep(colname,'+','_');
        for kk=1:length(colname);
            cout.([ 'ham_' colname{kk} '_gm'])(k) = S.hammers.data.Vgm(kk);
            cout.([ 'ham_' colname{kk} '_wm'])(k) = S.hammers.data.Vwm(kk);
            cout.([ 'ham_' colname{kk} '_csf'])(k) = S.hammers.data.Vcsf(kk);
        end
        
        found=1;
    end
    
    if ~found
        fprintf('Suject %s failled (no field) \n',fin{k});
        dir_missing(end+1) = fin{k};
    end
    
    
    
    
end




