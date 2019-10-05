function c = read_cat12_mat(fin)
%fin list of


mark2rps = @(mark) min(100,max(0,105 - mark*10));

load(fin{1})

%init
if isfield(S,'qualitymeasures')
    
    cfield = {'meanB','meanC','meanG','meanW','stdB','stdC','stdG','stdW','contrast','contrastr',...
        'NCR','ICR','qr_noise','qr_bias','IQR','vol_C','vol_G','vol_W','vol_WH','sr_TIV','SQR'}
    vinit = ones(size(fin))*NaN; for kk =1:length(cfield), c.(cfield{kk})=vinit;end
end

for k=1:length(fin)
    try 
        load(fin{k})
    catch 
        fprintf('corupt %s\n',fin{k})
        continue
        
    end
    
    found=0;
    
    if isfield(S,'qualitymeasures')
        c.suj{k} = fin{k};
        c.meanB(k) = S.qualitymeasures.tissue_mn(1);c.meanC(k) = S.qualitymeasures.tissue_mn(2);
        c.meanG(k) = S.qualitymeasures.tissue_mn(3);c.meanW(k) = S.qualitymeasures.tissue_mn(4);
        c.stdB(k) = S.qualitymeasures.tissue_std(1);c.stdC(k) = S.qualitymeasures.tissue_std(2);
        c.stdG(k) = S.qualitymeasures.tissue_std(3);c.stdW(k) = S.qualitymeasures.tissue_std(4);
        c.contrast(k) = S.qualitymeasures.contrast; c.contrastr(k) = S.qualitymeasures.contrastr;
        c.NCR(k) = S.qualitymeasures.NCR;c.ICR(k) = S.qualitymeasures.ICR;
        
        c.qr_noise(k) = mark2rps(S.qualityratings.NCR);
        c.qr_bias(k)  = mark2rps(S.qualityratings.ICR);
        c.IQR(k)      = mark2rps(S.qualityratings.IQR);
        
        c.vol_C(k) = S.subjectmeasures.vol_abs_CGW(1);c.vol_G(k) = S.subjectmeasures.vol_abs_CGW(2);
        c.vol_W(k) = S.subjectmeasures.vol_abs_CGW(3);c.vol_WH(k) = S.subjectmeasures.vol_abs_CGW(4);
        c.sr_TIV(k) = S.subjectratings.vol_TIV; c.SQR(k) = S.subjectratings.SQR;
        
        found=1;
    end
    if isfield(S,'lpba40')
        
        colname = S.lpba40.names; colname = strrep(colname,'+','_');
        for kk=1:length(colname)
            c.([ 'ba40_' colname{kk} '_gm'])(k) = S.lpba40.data.Vgm(kk);
        end
        
        found=1;
    end
    
    if isfield(S,'hammers')
        
        colname = S.hammers.names;  colname = strrep(colname,'+','_');
        for kk=1:length(colname);
            c.([ 'ham_' colname{kk} '_gm'])(k) = S.hammers.data.Vgm(kk);
            c.([ 'ham_' colname{kk} '_wm'])(k) = S.hammers.data.Vwm(kk);
            c.([ 'ham_' colname{kk} '_csf'])(k) = S.hammers.data.Vcsf(kk);
        end
        
        found=1;
    end
    
    if ~found
        fprintf('Suject %s failled\n',fin{k});
    end
    
    
    
    
end




