function do_fsl_transformation_matrix(src,ref,tmout)


for k=1:length(src)
    cmd = sprintf('flirt -in %s -ref %s -usesqform -applyxfm  -omat %s ',src{k},ref{k},tmout{k});
    unix(cmd);
    %cmd        
end

            
