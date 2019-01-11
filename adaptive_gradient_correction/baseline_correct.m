function [ EEG ] = BaselineCorrect(EEG, n_channels, TR, Peak_references, weighting_matrix, baseline_method, onset_value, offset_value, ref_start, ref_end, extra_data)

try
   lim1 = length(Peak_references);
   lim2 = length(weighting_matrix);
   residual = lim1 - lim2 + 1;
   switch baseline_method
       case 1 % 1 - Based on WHOLE ARTIFACT to zero
           baseline = 0;
           % Do corrected data
           for ch = 1: n_channels
               for i = residual  : lim1
                   starter = Peak_references(i)+onset_value;
                   ender = Peak_references(i)+offset_value;
                   artif_average = mean(EEG(ch,starter:ender));
                   adjust = baseline - artif_average;
                   if abs(adjust) > precision
                       for j=starter:ender
                           EEG(ch,j) = EEG(ch,j) + adjust;
                       end
                   end
               end
           end
           st = Peak_references(residual) + onset_value;
           en = Peak_references(lim1) + offset_value;

       case 2 % 2 - Average of precedent silent gap
           for ch = 1: n_channels
               for i = residual  : lim1
                   try
                       baseline_start = Peak_references(i) + ref_start;
                       baseline_end = Peak_references(i) + ref_end;
                       baseline = mean(EEG(ch,baseline_start:baseline_end));
                   catch
                       baseline = 0;
                   end
                   starter = Peak_references(i)+onset_value;
                   ender = Peak_references(i)+offset_value;
                   artif_average = mean(EEG(ch,starter:ender));
                   adjust = baseline - artif_average;
                   if abs(adjust) > precision
                       for j=starter:ender
                           EEG(ch,j) = EEG(ch,j) + adjust;
                       end
                   end
               end
           end
           st = Peak_references(residual) + onset_value;
           en = Peak_references(lim1) + offset_value;
           
       case 3
          for ch = 1: n_channels
               for i = residual  : lim1
                   try
                       baseline_start = Peak_references(i-1) + ref_end;
                       baseline_end = Peak_references(i) + ref_start -1 ;
                       baseline = mean(EEG(ch,baseline_start:baseline_end));
                   catch
                       baseline = 0;
                   end
                   starter = Peak_references(i)+ref_start;
                   ender = Peak_references(i)+ref_end;
                   artif_average = mean(EEG(ch,starter:ender));
                   adjust = baseline - artif_average;
                   if abs(adjust) > precision
                       for j=starter:ender
                           EEG(ch,j) = EEG(ch,j) + adjust;
                       end
                   end
               end
           end
           st = Peak_references(residual) + ref_start;
           en = Peak_references(lim1) + ref_end;
   end   
   % Shift also non corrected data
   if extra_data == 1
       boundary1 = fix(Peak_references(residual)+onset_value-1); % start of fMRI gradients
       boundary2 = fix(Peak_references(lim1)+offset_value+1); % end of fMRI gradients
       for ch = 1: n_channels
           switch baseline_method
               case 1
                   baseline = 0;
               otherwise
                   baseline1 = mean(EEG(ch,st:st+TR));
                   baseline2 = mean(EEG(ch,en:en+TR));
           end
           lim3 = length(EEG(ch,:)); 
           adjust = baseline1 - mean(EEG(ch,1:boundary1));
           if abs(adjust) > precision
               for i=1:boundary1
                   EEG(ch,i) = EEG(ch,i) + adjust;
               end
           end
           adjust = baseline2 - mean(EEG(ch,boundary2:end));
           if abs(adjust) > precision
                for i=boundary2:lim3 % Channel could happen to turn disconected during recording
                     EEG(ch,i) = EEG(ch,i) + adjust;
                end
           end
       end
   end
end
