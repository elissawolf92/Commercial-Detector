u  = coder.typeof(0,[8192,2],[1 0]); 

tunedparams.CenterFrequency  = NaN;
tunedparams.Bandwidth        = NaN;
tunedparams.Gain             = NaN;
tunedparams.CenterFrequency2 = NaN;
tunedparams.Bandwidth2       = NaN;
tunedparams.Gain2            = NaN;


codegen audio_algorithm_peqso.m -args {u,tunedparams} -report
