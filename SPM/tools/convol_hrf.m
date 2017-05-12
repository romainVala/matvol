
tr    = 3;
hrf   = spm_hrf(tr);
task  = repmat([ones(1,10) zeros(1,10)], [1 5]);
final = conv(task,hrf);
figure; plot(final(1:length(task)));

hrf   = spm_hrf(tr/16);

