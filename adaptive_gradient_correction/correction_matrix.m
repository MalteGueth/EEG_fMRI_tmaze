function [EEG] = correction_matrix(EEG, n_channels, weighting_matrix, artifactOnsets, onset_value, offset_value)

lim1 = length(artifactOnsets);
lim2 = length(weighting_matrix);
residual = lim2-lim1+1;

step=0;
total=n_channels*lim2*2;
for ch = 1:n_channels+1
    if ch > n_channels
        for i = residual  : lim2
            step = step+1;
            step_srt = num2str((step/total)*100);
            starter = fix(artifactOnsets(i)+onset_value);
            ender = fix(artifactOnsets(i)+offset_value);
            EEG(ch-1,starter:ender) = CorrectionM(i,:);
        end
    else
        for i = residual  : lim2
            step = step+1;
            steptosrt = (step/total)*100;
            starter = fix(artifactOnsets(i)+onset_value);
            ender = fix(artifactOnsets(i)+offset_value);
            A(i,:) = (EEG(ch,starter:ender))';
            if ch > 1
                EEG(ch-1,starter:ender) = CorrectionM(i,:);
            end
        end
        A;
        for i= residual : lim2
            step = step+1;
            steptosrt = (step/total)*100;
            w=weighting_matrix(i,:)/sum(weighting_matrix(i,:));
            Correctionmatrix (i,:) = w*A;
        end

        CorrectionM(:,:) = A - Correctionmatrix;
    end
end
end
