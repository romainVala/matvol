function eff = design_efficiency(fmat)

if exist(fmat{1},'dir')
    fmat = get_subdir_regex_files(fmat,'SPM.mat',1)
end

for k=1:length(fmat)
    l = load(fmat{k});
    X = l.SPM.xX.X;
    nkX = l.SPM.xX.nKX;
    nkX2 = l.SPM.xX.xKXs.X;
    fprintf('\nWorking on %s \n',fmat{k});
    
    for nbc = 1:length(l.SPM.xCon)
        c = l.SPM.xCon(nbc).c;
        
        %trace(c'*inv(X'*X)*c);
        eff(k,nbc) = 1/trace(c'*inv(X'*X)*c);
        effnk(k,nbc) = 1/trace(c'*inv(nkX'*nkX)*c);
        effnk2(k,nbc) = 1/trace(c'*inv(nkX2'*nkX2)*c);
        
        fprintf('Contrast : %s \t %f \t %f \t %f \n ',l.SPM.xCon(nbc).name,eff(k,nbc),effnk(k,nbc),effnk2(k,nbc));
    end
    
    
end
