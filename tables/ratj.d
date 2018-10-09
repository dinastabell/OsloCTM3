# RATEFILE GENERATED USING *SELECT* AND ACMSU REACTION DATABASE                                     
# MASTER RATEFILE: photol.d                                                                         
# REACTION NETWORK: OPEN                                                                            
# PHOTOLYSIS REACTIONS - MASTER RATEFILE - Paul Brown, Oliver Wild & David Rowley                   
# Centre for Atmospheric Science, Cambridge, U.K.  Release date:  22 November 1993                  
# SCCS version information: @(#)photol.d	1.2 5/11/94                                         
    1 H2O2       PHOTON     OH         OH                   0.00E+00  0.00    100.0  H2O2     
    2 HCHO       PHOTON     CO         H2                   0.00E+00  0.00    100.0  H2COb    
    3 HCHO       PHOTON     CO         HO2        HO2       0.00E+00  0.00    100.0  H2COa    
    4 HO2NO2     PHOTON     OH         NO3                  0.00E+00  0.00     33.3  HNO4     
    5 HO2NO2     PHOTON     HO2        NO2                  0.00E+00  0.00     66.7  HNO4     
    6 HONO2      PHOTON     OH         NO2                  0.00E+00  0.00    100.0  HNO3     
    7 MeOOH      PHOTON     HCHO       OH         HO2       0.00E+00  0.00    100.0  CH3OOH     
#    8 MeOOH      PHOTON     HCHO       O3         HO2       0.00E+00  0.00     50.0  CH3OOH     
    9 N2O5       PHOTON     NO3        NO2                  0.00E+00  0.00    100.0  N2O5     
   10 N2O5       PHOTON     NO3        NO         O3        0.00E+00  0.00      0.0  N2O5     
   11 NO2        PHOTON     NO         O3                   0.00E+00  0.00    100.0  NO2      
   12 NO3        PHOTON     NO         O2                   0.00E+00  0.00     11.4  NO3  
   13 NO3        PHOTON     NO2        O3                   0.00E+00  0.00     88.6  NO3   
   14 O2         PHOTON     O3         O3                   0.00E+00  0.00    100.0  O2       
   15 O3         PHOTON     O2         O3                   0.00E+00  0.00    100.0  O3       
#   16 O3         PHOTON     O2         O3(1D)               0.00E+00  0.00    100.0  O3(1D)   
   17 MeCHO      PHOTON     MeOO       HO2        CO        0.00E+00  0.00    100.0  ActAld   
   18 MeCHO      PHOTON     CH4        CO                   0.00E+00  0.00      0.0  ActAld   
   19 PAN        PHOTON     MeCO3      NO2                  0.00E+00  0.00    100.0  PAN      
   20 EtOOH      PHOTON     MeCHO      HO2        OH        0.00E+00  0.00    100.0  CH3OOH     
   21 MeONO2     PHOTON     NO2        HCHO       HO2       0.00E+00  0.00    100.0  CH3NO3
   22 EtONO2     PHOTON     NO2        MeCHO      HO2       0.00E+00  0.00    142.6  CH3NO3     
 9999                                                       0.00E-00  0.00      0.0                 
                                                                                 
                                                                                 
                                                                                 
 NOTES:                                                                          
 -----                                                                           
  All reaction data taken from IUPAC supplement IV unless                        
  otherwise indicated.                                                           
                                                                                 
  JPL - data from JPL (latest assessment as far as possible)                     
                                                                                 
  ? - reaction products unknown                                                  
  * - user strongly advised to consult source material                           
  B - branching ratio assumed equal for all channels in the                      
       absence of more information                                               
  U - upper limit for rate coefficient                                           
                                                                                 
                                                                                 
 Changes since 08/3/93 release:                                                  
  O now written as O3(3P)                                                        
                                                                                 
