//*********************************************************************
 /*  SS_Label_Function_14 #Get_MGsetup:  apply time-varying factors this year to the MG parameters to create mgp_adj vector */
FUNCTION void get_MGsetup()
  {
  mgp_adj=MGparm;
  int y1;

  //  SS_Label_Info_14.1 #Calculate any trends that will be needed for any of the MG parameters
  if(N_MGparm_trend>0)
  {
    for (f=1;f<=N_MGparm_trend;f++)
    {
      j=MGparm_trend_rev(f);  //  parameter affected
      k=MGparm_trend_rev_1(f);  // base index for trend parameters
      if(y==styr)
      {
        //  calc endyr value, but use logistic transform to keep with bounds of the base parameter
        if(MGparm_1(j,13)==-1)
        {
          temp=log((MGparm_1(j,2)-MGparm_1(j,1)+0.0000002)/(MGparm(j)-MGparm_1(j,1)+0.0000001)-1.)/(-2.);   // transform the base parameter
          temp+=MGparm(k+1);     //  add the offset  Note that offset value is in the transform space
          temp1=MGparm_1(j,1)+(MGparm_1(j,2)-MGparm_1(j,1))/(1.+mfexp(-2.*temp));   // backtransform
        }
        else if(MGparm_1(j,13)==-2)
        {
          temp1=MGparm(k+1);  // set ending value directly
        }

        if(MGparm_HI(k+2)<=1.1)  // use max bound as switch
        {temp3=r_years(styr)+MGparm(k+2)*(r_years(endyr)-r_years(styr));}  // infl year
        else
        {temp3=MGparm(k+2);}

        temp2=cumd_norm((r_years(styr)-temp3)/MGparm(k+3));     //  cum_norm at styr
        temp=(temp1-MGparm(j)) / (cumd_norm((r_years(endyr)-temp3)/MGparm(k+3))-temp2);   //  delta in cum_norm between styr and endyr
        for (int y1=styr;y1<=YrMax;y1++)
        {
          if(y1<=endyr)
          {MGparm_trend(f,y1)=MGparm(j) + temp * (cumd_norm((r_years(y1)-temp3)/MGparm(k+3) )-temp2);}
          else
          {MGparm_trend(f,y1)=MGparm_trend(f,y1-1);}
        }
      }
      mgp_adj(j)=MGparm_trend(MGparm_trend_point(j),y);
    }
  }

  //  SS_Label_Info_14.2 #Else create MGparm block values
  else if (N_MGparm_blk>0)
  {
    for (j=1;j<=N_MGparm;j++)
    {
      z=MGparm_1(j,13);    // specified block pattern
      if(z>0)  // uses blocks
      {
        if(y==styr)  // set up the block values time series
        {
          g=1;
          if(MGparm_1(j,14)<3)
          {
            for (a=1;a<=Nblk(z);a++)
            {
              for (int y1=Block_Design(z,g);y1<=Block_Design(z,g+1);y1++)  // loop years for this block
              {
                k=Block_Defs_MG(j,y1);  // identifies parameter that holds the block effect
                MGparm_block_val(j,y1)=MGparm(k);
              }
              g+=2;
            }
          }
          else
          {
            temp=0.0;
            for (a=1;a<=Nblk(z);a++)
            {
              y1=Block_Design(z,g);   // first year of block
              k=Block_Defs_MG(j,y1);  // identifies parameter that holds the block effect
              temp+=MGparm(k);  // increment by the block delta
              for (int y1=Block_Design(z,g);y1<=Block_Design(z,g+1);y1++)  // loop years for this block
              {
                MGparm_block_val(j,y1)=temp;
              }
              g+=2;
            }
          }
        }  // end block setup
      }  // end uses blocks
    }  // end parameter loop
  }  // end block section

  //  SS_Label_Info_14.3 #Create MGparm dev randwalks if needed
  if(N_MGparm_dev>0 && y==styr)
  {
    for (k=1;k<=N_MGparm_dev;k++)
    {
      if(MGparm_dev_type(k)==3)  //   random walk
      {
        MGparm_dev_rwalk(k,MGparm_dev_minyr(k))=MGparm_dev(k,MGparm_dev_minyr(k));
        j=MGparm_dev_minyr(k);
        for (j=MGparm_dev_minyr(k)+1;j<=MGparm_dev_maxyr(k);j++)
        {
          MGparm_dev_rwalk(k,j)=MGparm_dev_rwalk(k,j-1)+MGparm_dev(k,j);
        }
      }
      else if(MGparm_dev_type(k)==4) // mean reverting random walk
      {
        MGparm_dev_rwalk(k,MGparm_dev_minyr(k))=MGparm_dev(k,MGparm_dev_minyr(k));
        j=MGparm_dev_minyr(k);
        for (j=MGparm_dev_minyr(k)+1;j<=MGparm_dev_maxyr(k);j++)
        {
          //    =(1-rho)*mean + rho*prevval + dev   //  where mean = 0.0
          MGparm_dev_rwalk(k,j)=MGparm_dev_rho(k)*MGparm_dev_rwalk(k,j-1)+MGparm_dev(k,j);
        }
      }
    }
  }

  //  SS_Label_Info_14.4 #Switch(MG_adjust_method)
  switch(MG_adjust_method)
  {
    case 3:
    {
      //  no break statement, so will execute case 1 code
    }
  //  SS_Label_Info_14.4.1 #Standard MG_adjust_method (1 or 3), loop MGparms
    case 1:
    {
      for (f=1;f<=N_MGparm;f++)
      {
  //  SS_Label_Info_14.4.1.1 #Adjust for blocks
        if(MGparm_1(f,13)>0)   // blocks
        {
          if(Block_Defs_MG(f,yz)>0)
          {
            if(MGparm_1(f,14)==0)
              {mgp_adj(f) *= mfexp(MGparm_block_val(f,yz));}
            else if(MGparm_1(f,14)==1)
              {mgp_adj(f) += MGparm_block_val(f,yz);}
            else if(MGparm_1(f,14)==2)
              {mgp_adj(f) = MGparm_block_val(f,yz);}
            else if(MGparm_1(f,14)==3)  // additive based on delta approach
              {mgp_adj(f) += MGparm_block_val(f,yz);}
          }
        }

  //  SS_Label_Info_14.4.1.2 #Adjust for env linkage
  //  June 6 begin to add 2 parameter env linkages
  //  P1 will be the current "slope" and P2 will be a new offset
  //  also add a logistic function
        if(MGparm_env(f)>0)
        {
          switch(MGparm_envtype(f))
          {
            case 1:  //  exponential MGparm env link
              {
                mgp_adj(f)*=mfexp(MGparm(MGparm_env(f))*(env_data(yz,MGparm_envuse(f))-MGparm(MGparm_env(f))));
                break;
              }
            case 2:  //  linear MGparm env link
              {
                mgp_adj(f)+=MGparm(MGparm_env(f))*(env_data(yz,MGparm_envuse(f))-MGparm(MGparm_env(f)));
                break;
              }
            case 3:  //  logistic MGparm env link
              {
                mgp_adj(f)*=2.00000/(1.00000 + mfexp(-MGparm(MGparm_env(f))*(env_data(yz,MGparm_envuse(f))-MGparm(MGparm_env(f)))));
                break;
              }
          }
        }

  //  SS_Label_Info_14.4.1.3 #Adjust for Annual deviations
        k=MGparm_dev_point(f);
        if(k>0)
        {
          if(yz>=MGparm_dev_minyr(k) && yz<=MGparm_dev_maxyr(k))
          {
            if(MGparm_dev_type(k)==1)  // multiplicative
            {mgp_adj(f) *= mfexp(MGparm_dev(k,yz));}
            else if(MGparm_dev_type(k)==2)  // additive
            {mgp_adj(f) += MGparm_dev(k,yz);}
            else if(MGparm_dev_type(k)>=3)  // additive rwalk or mean-reverting rwalk
            {mgp_adj(f) += MGparm_dev_rwalk(k,yz);}
          }
        }

  //  SS_Label_Info_14.4.1.4 #Do bound check if MG_adjust_method=1
        if(MG_adjust_method==1 && (save_for_report==1 || do_once==1))  // so does not check bounds if MG_adjust_method==3
        {
          if(mgp_adj(f)<MGparm_1(f,1) || mgp_adj(f)>MGparm_1(f,2))
          {
            N_warn++;
            warning<<" adjusted MGparm out of bounds (parm#, yr, min, max, base, adj_value) "<<f<<" "<<yz<<" "<<
            MGparm_1(f,1)<<" "<<MGparm_1(f,2)<<" "<<MGparm(f)<<" "<<mgp_adj(f)<<" "<<ParmLabel(f)<<endl;
          }
        }
      }  // end parameter loop (f)
      break;
    }

  //  SS_Label_Info_14.4.2 #Constrained MG_adjust_method (2), loop MGparms
    case 2:
    {
      for (f=1;f<=N_MGparm;f++)
      {
        j=0;
        temp=log((MGparm_HI(f)-MGparm_LO(f)+0.0000002)/(mgp_adj(f)-MGparm_LO(f)+0.0000001)-1.)/(-2.);   // transform the parameter

  //  SS_Label_Info_14.4.2.1 #Adjust for blocks
        if(MGparm_1(f,13)>0)   // blocks
        {
          if(Block_Defs_MG(f,yz)>0)
          {
            j=1;  //  change is being made
            if(MGparm_1(f,14)==1)
              {temp+=MGparm_block_val(f,yz);}
            else if(MGparm_1(f,14)==2)  // block as replacement
              {temp=log((MGparm_HI(f)-MGparm_LO(f)+0.0000002)/(MGparm_block_val(f,yz)-MGparm_LO(f)+0.0000001)-1.)/(-2.);}
            else if(MGparm_1(f,14)==3)  // additive based on delta approach
              {temp += MGparm_block_val(f,yz);}
          }
        }

  //  SS_Label_Info_14.4.2.2 #Adjust for env linkage
        if(MGparm_env(f)>0)  //  do environmental effect;  only additive allowed for adjustment method=2
        {j=1; temp+=MGparm(MGparm_env(f))* env_data(yz,MGparm_envuse(f));}

  //  SS_Label_Info_14.4.2.3 #Adjust for annual deviations
        k=MGparm_dev_point(f);
        if(k>0)
        {
          if(yz>=MGparm_dev_minyr(k) && yz<=MGparm_dev_maxyr(k))
            {
              j=1;
              if(MGparm_dev_type(k)==2)
              {temp += MGparm_dev(k,yz);}
              else if(MGparm_dev_type(k)>=3)
              {temp += MGparm_dev_rwalk(k,yz);}  // note that only additive effect is allowed
            }
        }
        if(j==1) mgp_adj(f)=MGparm_LO(f)+(MGparm_HI(f)-MGparm_LO(f))/(1.+mfexp(-2.*temp));   // backtransform
      }  // end parameter loop (f)
      break;
    }  // end case 2
  }   // end switch method

  //  SS_Label_Info_14.5 #if MGparm method =1 (no offsets), then do direct assignment if parm value is 0.0. (only for natMort and growth parms)
  if(MGparm_def==1)
  {
    for (j=1;j<=N_MGparm;j++)
    {
      if(MGparm_offset(j)>0) mgp_adj(j) = mgp_adj(MGparm_offset(j));
    }
  }
  if(save_for_report>0) mgp_save(yz)=value(mgp_adj);
  }

//********************************************************************
 /*  SS_Label_FUNCTION 15 get_growth1;  calc some seasonal and CV_growth biology factors that cannot be time-varying */
FUNCTION void get_growth1()
  {
  //  SS_Label_Info_15.1  #create seasonal effects for growth K, and for wt_len parameters
    if(MGparm_doseas>0)
    {
      if(MGparm_seas_effects(10)>0)  // for seasonal K
      {
        VBK_seas(0)=0.0;
        for (s=1;s<=nseas;s++)
        {
          VBK_seas(s)=mfexp(MGparm(MGparm_seas_effects(10)+s));
          VBK_seas(0)+=VBK_seas(s)*seasdur(s);
        }
      }
      else
      {
        VBK_seas=sum(seasdur);  // set vector to null effect
      }

      for(gp=1;gp<=N_GP;gp++)
      for (j=1;j<=8;j++)
      {
        if(MGparm_seas_effects(j)>0)
        {
          wtlen_seas(0,gp,j)=0.0;
          for (s=1;s<=nseas;s++)
          {
            wtlen_seas(s,gp,j)=mfexp(MGparm(MGparm_seas_effects(j)+s));
            wtlen_seas(0,gp,j)+=wtlen_seas(s,gp,j)*seasdur(s);  //  this seems not to be used
          }
        }
        else
        {
          for (s=0;s<=nseas;s++) {wtlen_seas(s,gp,j)=1.0;}
        }
      }
    }
    else
    {
      VBK_seas=sum(seasdur);  // set vector to null effect
      for(s=1;s<=nseas;s++) wtlen_seas(s)=1.0;  // set vector to null effect
    }

  //  SS_Label_Info_15.2  #create variability of size-at-age factors using direct assignment or offset approaches
      gp=0;
      for (gg=1;gg<=gender;gg++)
      for (g=1;g<=N_GP;g++)
      {
        gp++;
        Ip=MGparm_point(gg,g);
        j=Ip+N_M_Grow_parms-2;  // index for CVmin
        k=j+1;  // index for CVmax
        switch(MGparm_def)    // for CV of size-at-age
          {
            case 1:  // direct
            {
            if(MGparm(j)>0)
              {CVLmin(gp)=MGparm(j);} else {CVLmin(gp)=MGparm(N_M_Grow_parms-1);}
            if(MGparm(k)>0)
              {CVLmax(gp)=MGparm(k);} else {CVLmax(gp)=MGparm(N_M_Grow_parms);}
            break;
            }
            case 2:  // offset
            {
            if(gp==1)
              {CVLmin(gp)=MGparm(j); CVLmax(gp)=MGparm(k);}
            else
              {CVLmin(gp)=CVLmin(1)*mfexp(MGparm(j)); CVLmax(gp)=CVLmax(1)*mfexp(MGparm(k));}
            break;
            }
            case 3:  // offset like SS2 V1.23
            {
            if(gp==1)
              {CVLmin(gp)=MGparm(j); CVLmax(gp)=CVLmin(1)*mfexp(MGparm(k));}
            else
              {CVLmin(gp)=CVLmin(1)*mfexp(MGparm(j)); CVLmax(gp)=CVLmin(gp)*mfexp(MGparm(k));}
            break;
            }
          }  // end switch
          if((CVLmin(gp)!=CVLmax(gp)) || active(MGparm(N_M_Grow_parms)) || active(MGparm(k)))
          {CV_const(gp)=1;} else {CV_const(gp)=0;}
        }
  }

//********************************************************************
 /*  SS_Label_Function_ 16 #get_growth2; (do seasonal growth calculations for a selected year) */
FUNCTION void get_growth2()
  {
//  progress mean growth through time series, accounting for seasonality and possible change in parameters
//   get mean size at the beginning and end of the season
//    dvariable grow;
    int k2;
    int add_age;
    int ALK_idx2;  //  beginning of first subseas of next season
    dvariable plusgroupsize;
    dvariable current_size;
  //  SS_Label_Info_16.1 #Create Cohort_Growth offset for the cohort borne (age 0) this year
    if(CGD>0)   //  cohort specific growth multiplier
    {
      temp=mgp_adj(MGP_CGD);
      k=min(nages,(YrMax-y));
      for (a=0;a<=k;a++) {Cohort_Growth(y+a,a)=temp;}  //  so this multiplier on VBK is stored on a diagonal into the future
    }
  
  //  SS_Label_Info_16.2 #Loop growth patterns (sex*N_GP)
    gp=0;
    for(gg=1;gg<=gender;gg++)
    for (GPat=1;GPat<=N_GP;GPat++)
    {
      gp++;
      Ip=MGparm_point(gg,GPat)+N_natMparms;
//  SS_Label_Info_16.2.1  #set Lmin, Lmax, VBK, Richards to this year's values for mgp_adj
      if(MGparm_def>1 && gp>1)   // switch for growth parms
      {
        Lmin(gp)=Lmin(1)*mfexp(mgp_adj(Ip));
        Lmax_temp(gp)=Lmax_temp(1)*mfexp(mgp_adj(Ip+1));
        VBK(gp)=VBK(1)*mfexp(mgp_adj(Ip+2));  //  assigns to all ages
      }
      else
      {
        Lmin(gp)=mgp_adj(Ip);
        Lmax_temp(gp)=mgp_adj(Ip+1);
        VBK(gp)=-mgp_adj(Ip+2);  // because always used as negative; assigns to all ages
      }
      
//  SS_Label_Info_16.2.2  #Set up age specific k
      if(Grow_type==3)  //  age specific k
      {
        j=1;
        for (a=1;a<=nages;a++)
        {
          if(a==Age_K_points(j))
          {
            VBK(gp,a)=VBK(gp,a-1)*mgp_adj(Ip+2+j);
            if(j<Age_K_count) j++;
          }
          else
          {
            VBK(gp,a)=VBK(gp,a-1);
          }
        }
      }

//  SS_Label_Info_16.2.3  #Set up Lmin and Lmax in Start Year
      if(y==styr)
      {
        Cohort_Lmin(gp)=Lmin(gp);   //  sets for all years and ages
      }
      else if(time_vary_MG(y,2)>0)  //  using time-vary growth
      {
        k=min(nages,(YrMax-y));
        for (a=0;a<=k;a++) {Cohort_Lmin(gp,y+a,a)=Lmin(gp);}  //  sets for future years so cohort remembers its size at birth; with Lmin(gp) being size at birth this year
      }

      if(AFIX2==999)
      {L_inf(gp)=Lmax_temp(gp);}
      else
      {
        L_inf(gp)=Lmin(gp)+(Lmax_temp(gp)-Lmin(gp))/(1.-mfexp(VBK(gp,nages)*VBK_seas(0)*(AFIX_delta)));
      }

      g=g_Start(gp);  //  base platoon
//  SS_Label_Info_16.2.4  #Loop settlement events
      for (settle=1;settle<=N_settle_timings;settle++)
      {
        g+=N_platoon;
        if(use_morph(g)>0)
        {
          if(y==styr)
          {
//  SS_Label_Info_16.2.4.1  #set up the delta in growth variability across ages if needed
    if( g==1 && do_once==1) echoinput<<y<<" initial yr do CV setup for gp, g: "<<gp<<" "<<g<<endl;
            if(CV_const(gp)>0)
            {
              if(CV_depvar_a==0)
                {CV_delta(gp)=(CVLmax(gp)-CVLmin(gp))/(Lmax_temp(gp)-Lmin(gp));}
              else
                {CV_delta(gp)=(CVLmax(gp)-CVLmin(gp))/(AFIX2_forCV-AFIX);}
            }
            else
            {
              CV_delta(gp)=0.0;
              CV_G(gp)=CVLmin(gp);  // sets all seasons and whole age range
            }

//  SS_Label_Info_16.2.4.1.1  #if y=styr, get size-at-age in first subseason of first season of this first year
            if(do_once==1) echoinput<<y<<" seas: "<<s<<" growth gp,g: "<<gp<<" "<<g<<" settle_age "<<Settle_age(settle)<<" Lmin: "<<Lmin(gp)<<" Linf: "<<L_inf(gp)<<endl<<" K@age: "<<-VBK(gp)<<endl;
            Ave_Size(styr,1,g,0)=L_inf(gp) + (Lmin(gp)-L_inf(gp))*mfexp(VBK(gp,0)*VBK_seas(0)*(real_age(g,1,0)-AFIX));
            for (a=1;a<=nages+Settle_age(settle);a++)
            {
              a1=a-Settle_age(settle);
                Ave_Size(styr,1,g,a1) = Lmin(gp) + (Lmin(gp)-L_inf(gp))* (mfexp(VBK(gp,0)*VBK_seas(0)*(real_age(g,1,a1)-AFIX))-1.0);
            }  // done ageloop

            if(do_once==1) echoinput<<" L@A(w/o lin): "<<Ave_Size(styr,1,g)<<endl;

//  SS_Label_Info_16.2.4.1.4  #calc approximation to mean size at maxage to account for growth after reaching the maxage (accumulator age)
            current_size=Ave_Size(styr,1,g,nages);
            temp1=1.0;
            temp4=1.0;
            temp=current_size;
            temp2=mfexp(-0.08);  //  cannot use natM or Z because growth is calculated first
            if(do_once==1&&g==1) echoinput<<" L_inf "<<L_inf(gp)<<" size@exactly maxage "<<current_size<<endl;
            for (a=nages+1;a<=3*nages;a++)
            {
              temp4*=temp2;  //  decay numbers at age by exp(-0.xxx)
              current_size+=(L_inf(gp)-current_size)* (1.0-mfexp(VBK(gp,0)*VBK_seas(0)));
              temp+=temp4*current_size;
              temp1+=temp4;   //  accumulate numbers to create denominator for mean size calculation
              if(do_once==1&&g==1) echoinput<<a<<" "<<temp4<<" "<<current_size<<" "<<temp/temp1<<endl;
            }
            Ave_Size(styr,1,g,nages)=temp/temp1;  //  this is weighted mean size at nages
            if(do_once==1&&g==1) echoinput<<" adjusted size at maxage "<<Ave_Size(styr,1,g,nages)<<endl
              <<" ratio "<<temp1/temp2<<endl;
          }  //  end initial year calcs

//  SS_Label_Info_16.2.4.2  #loop seasons for growth calculation
          for (s=1;s<=nseas;s++)
          {
            t=t_base+s;
            ALK_idx=s*N_subseas;  // last subseas of season; so checks to see if still in linear phase at end of this season
            if(s==nseas)
            {
              ALK_idx2=1;  //  first subseas of next year
            }
            else
            {
              ALK_idx2=s*N_subseas+1;  //  for the beginning of first subseas of next season
            }
            if(s==nseas) add_age=1; else add_age=0;   //      advance age or not
// growth to next season
//  SS_Label_Info_16.2.4.2.1  #standard von Bert growth, loop ages to get size at age at beginning of next season (t+1) which is subseas=1
            for (a=0;a<=nages;a++)
            {
              if(a<nages) {k2=a+add_age;} else {k2=a;}  // where add_age =1 if s=nseas, else 0  (k2 assignment could be in a matrix so not recalculated
// NOTE:  there is no seasonal interpolation, or real age adjustment for age-specific K.  Maybe someday....
              if(lin_grow(g,ALK_idx,a)==-1.0)  // first time point beyond AFIX;  lin_grow will stay at -1 for all remaining subseas of this season
              {
                Ave_Size(t+1,1,g,k2) = Cohort_Lmin(gp,y,a) + (Cohort_Lmin(gp,y,a)-L_inf(gp))*
                (mfexp(VBK(gp,a)*(real_age(g,ALK_idx2,k2)-AFIX)*VBK_seas(s))-1.0)*Cohort_Growth(y,a);
              }
              else if(lin_grow(g,ALK_idx,a)==-2.0)  //  so doing growth curve
              {
                t2=Ave_Size(t,1,g,a)-L_inf(gp);  //  remaining growth potential from first subseas
                if(time_vary_MG(y,2)>0 && t2>-1.)
                {
                  join1=1.0/(1.0+mfexp(-(50.*t2/(1.0+fabs(t2)))));  //  note the logit transform is not perfect, so growth near Linf will not be exactly same as with native growth function
                  t2*=(1.-join1);  // trap to prevent decrease in size-at-age
                }

//  SS_Label_info_16.2.4.2.1.1  #calc size at end of the season, which will be size at begin of next season using current seasons growth parms
                  //  with k2 adding an age if at the end of the year
                if((a<nages || s<nseas)) Ave_Size(t+1,1,g,k2) = Ave_Size(t,1,g,a) + (mfexp(VBK(gp,a)*seasdur(s)*VBK_seas(s))-1.0)*t2*Cohort_Growth(y,a);
                if(a==nages && s==nseas) plusgroupsize = Ave_Size(t,1,g,nages) + (mfexp(VBK(gp,nages)*seasdur(s)*VBK_seas(s))-1.0)*t2*Cohort_Growth(y,nages);
              }
            }  // done ageloop

//  SS_Label_Info_16.2.4.2.1.2  #after age loop, if(s=nseas) get weighted average for size_at_maxage from carryover fish and fish newly moving into this age
            if(s==nseas)
            {
              if(y>styr)
                {
                  temp4= square(natage(t,1,g,nages-1)+0.00000001)/(natage(t-1,1,g,nages-2)+0.00000001);
                  temp=temp4*Ave_Size(t+1,1,g,nages)+(natage(t,1,g,nages)-temp4+0.00000001)*plusgroupsize;
                  if(do_once==1&&g==1) echoinput<<" plus group "<<t<<" N "<<temp4<<" "<<natage(t,1,g,nages)<<
                  " size "<<Ave_Size(t+1,1,g,nages)<<" "<<plusgroupsize<<" ";
                  Ave_Size(t+1,1,g,nages)=temp/(natage(t,1,g,nages)+0.00000001);
                }
                else
                {               
                  Ave_Size(t+1,1,g,nages)=Ave_Size(t,1,g,nages);
                }
              if(do_once==1&&g==1) echoinput<<" new_val "<<Ave_Size(t+1,1,g,nages)<<endl;
            }

            if(docheckup==1) echoinput<<y<<" seas: "<<s<<" sex: "<<sx(g)<<" gp: "<<gp<<" settle: "<<settle_g(g)<<" Lmin: "<<Lmin(gp)<<" Linf: "<<L_inf(gp)<<" VBK: "<<VBK(gp,nages)<<endl
            <<" size@t+1   "<<Ave_Size(t+1,1,g)(0,min(6,nages))<<" "<<Ave_Size(t+1,1,g,nages)<<endl;
          }  // end of season
//  SS_Label_Info_16.2.4.3  #propagate Ave_Size from early years forward until first year that has time-vary growth
          k=y+1;
          j=yz+1;
          while(time_vary_MG(j,2)==0 && k<=YrMax)
          {
            for (s=1;s<=nseas;s++)
            {
              t=styr+(k-styr)*nseas+s-1;
              Ave_Size(t,1,g)=Ave_Size(t-nseas,1,g);
              if(s==1 && k<YrMax)
              {
                Ave_Size(t+nseas,1,g)=Ave_Size(t,1,g);  // prep for time-vary next yr
              }
            }  // end season loop
            k++;
            if(j<endyr+1) j++;
          }
        }  // end need to consider this GP x settlement combo (usemorph>0)
      }  // end loop of settlements
      Ip+=N_M_Grow_parms;
    }    // end loop of growth patterns, gp
//      warning<<current_phase()<<" "<<"growth "<<y<<" "<<Lmin(1)<<" "<<Lmax_temp(1)<<" "<<L_inf(1)<<" "<<VBK(1)(0,6)<<" size "<<Ave_Size(t,1,1)(0,6)<<endl;
  //  SS_Label_Info_16.2.4.4  #end of growth
  } // end do growth

//********************************************************************
 /*  SS_Label_Function_ 16a #get_growth2_Richards; (do seasonal growth calculations for a selected year) */
FUNCTION void get_growth2_Richards()
  {
//  progress mean growth through time series, accounting for seasonality and possible change in parameters
//   get mean size at the beginning and end of the season
    dvariable LminR;
    dvariable LmaxR;
    dvariable LinfR;
    dvariable inv_Richards;
    dvariable VBK_temp;  //  constant across ages with Richards
    dvariable VBK_temp2;  //  with VBKseas(s) multiplied
    int k2;
    int add_age;
    int ALK_idx2;  //  beginning of first subseas of next season
  //  SS_Label_Info_16.1 #Create Cohort_Growth offset for the cohort borne (age 0) this year
    if(CGD>0)   //  cohort specific growth multiplier
    {
      temp=mgp_adj(MGP_CGD);
      k=min(nages,(YrMax-y));
      for (a=0;a<=k;a++) {Cohort_Growth(y+a,a)=temp;}  //  so this multiplier on VBK is stored on a diagonal into the future
    }
  
  //  SS_Label_Info_16.2 #Loop growth patterns (sex*N_GP)
    gp=0;
    for(gg=1;gg<=gender;gg++)
    for (GPat=1;GPat<=N_GP;GPat++)
    {
      gp++;
      Ip=MGparm_point(gg,GPat)+N_natMparms;
//  SS_Label_Info_16.2.1  #set Lmin, Lmax, VBK, Richards to this year's values for mgp_adj
      if(MGparm_def>1 && gp>1)   // switch for growth parms
      {
        Lmin(gp)=Lmin(1)*mfexp(mgp_adj(Ip));
        Lmax_temp(gp)=Lmax_temp(1)*mfexp(mgp_adj(Ip+1));
        VBK(gp,nages)=VBK(1,nages)*mfexp(mgp_adj(Ip+2));
        VBK_temp=VBK(1,nages)*mfexp(mgp_adj(Ip+2));
        Richards(gp)=Richards(1)*mfexp(mgp_adj(Ip+3));
      }
      else
      {
        Lmin(gp)=mgp_adj(Ip);
        Lmax_temp(gp)=mgp_adj(Ip+1);
        VBK(gp,nages)=-mgp_adj(Ip+2);
        VBK_temp=-mgp_adj(Ip+2);  // because always used as negative; constant across ages for Richards
        Richards(gp)=mgp_adj(Ip+3);
      }
      
//  SS_Label_Info_16.2.3  #Set up Lmin and Lmax
      LminR=pow(Lmin(gp),Richards(gp));
      if(y==styr)
      {
        Cohort_Lmin(gp)=LminR;   //  sets for all years and ages
      }
      else if(time_vary_MG(y,2)>0)  //  using time-vary growth
      {
        k=min(nages,(YrMax-y));
        for (a=0;a<=k;a++) {Cohort_Lmin(gp,y+a,a)=LminR;}  //  sets for future years so cohort remembers its size at birth; with Lmin(gp) being size at birth this year
      }

      inv_Richards=1.0/Richards(gp);
      if(AFIX2==999)
      {
        L_inf(gp)=Lmax_temp(gp);
        LinfR=pow(L_inf(gp),Richards(gp));
      }
      else
      {
        LmaxR=pow(Lmax_temp(gp), Richards(gp));
        LinfR=LminR+(LmaxR-LminR)/(1.-mfexp(VBK_temp*VBK_seas(0)*(AFIX_delta)));
        L_inf(gp)=pow(LinfR,inv_Richards);
      }
      
      g=g_Start(gp);  //  base platoon
//  SS_Label_Info_16.2.4  #Loop settlement events
      for (settle=1;settle<=N_settle_timings;settle++)
      {
        g+=N_platoon;
        if(use_morph(g)>0)
        {
          if(y==styr)
          {
//  SS_Label_Info_16.2.4.1  #set up the delta in growth variability across ages if needed
            if( g==1 && do_once==1) echoinput<<y<<" initial yr do CV setup for gp, g: "<<gp<<" "<<g<<endl;
            if(CV_const(gp)>0)
            {
              if(CV_depvar_a==0)
                {CV_delta(gp)=(CVLmax(gp)-CVLmin(gp))/(Lmax_temp(gp)-Lmin(gp));}
              else
                {CV_delta(gp)=(CVLmax(gp)-CVLmin(gp))/(AFIX2_forCV-AFIX);}
            }
            else
            {
              CV_delta(gp)=0.0;
              CV_G(gp)=CVLmin(gp);  // sets all seasons and whole age range
            }

//  SS_Label_Info_16.2.4.1.1  #if y=styr, get size-at-age in first subseason of first season of this first year
            if(do_once==1) echoinput<<y<<" seas: "<<s<<" growth gp,g: "<<gp<<" "<<g<<" settle_age "<<Settle_age(settle)<<" Lmin: "<<Lmin(gp)<<" Linf: "<<L_inf(gp)<<" K(nages): "<<-VBK(gp,nages)<<endl;

            VBK_temp2=VBK_temp*VBK_seas(0);
            temp=LinfR + (LminR-LinfR)*mfexp(VBK_temp2*(real_age(g,1,0)-AFIX));
            Ave_Size(styr,1,g,0) = pow(temp,inv_Richards);
            first_grow_age=0;
            for (a=1;a<=nages+Settle_age(settle);a++)
            {
              a1=a-Settle_age(settle);
              temp=LinfR + (LminR-LinfR)*mfexp(VBK_temp2*(real_age(g,1,a1)-AFIX));
              Ave_Size(styr,1,g,a1) = pow(temp,inv_Richards);
            }  // done ageloop
            if(do_once==1&&g==1) echoinput<<" avesize_in_styr_w/o_linear_section "<<Ave_Size(styr,1,g)<<endl;

//  SS_Label_Info_16.2.4.1.4  #calc approximation to mean size at maxage to account for growth after reaching the maxage (accumulator age)
            temp=0.0;
            temp1=0.0;
            temp2=mfexp(-0.2);  //  cannot use natM or Z because growth is calculated first
            temp3=L_inf(gp)-Ave_Size(styr,1,g,nages);  // delta between linf and the size at nages
            //  frac_ages = age/nages, so is fraction of a lifetime
            temp4=1.0;
            for (a=0;a<=nages;a++)
            {
              temp+=temp4*(Ave_Size(styr,1,g,nages)+frac_ages(a)*temp3);  // so grows linearly from size at nages to size at nages+nages
              temp1+=temp4;   //  accumulate numbers to create denominator for mean size calculation
              temp4*=temp2;  //  decay numbers at age by exp(-0.2)
            }
            Ave_Size(styr,1,g,nages)=temp/temp1;  //  this is weighted mean size at nages
            if(do_once==1&&g==1) echoinput<<" adjusted size at maxage "<<Ave_Size(styr,1,g,nages)<<endl;
          }  //  end initial year calcs

//  SS_Label_Info_16.2.4.2  #loop seasons for growth calculation
          for (s=1;s<=nseas;s++)
          {
            t=t_base+s;
            ALK_idx=s*N_subseas;  // last subseas of season; so checks to see if still in linear phase at end of this season
            if(s==nseas)
            {
              ALK_idx2=1;  //  first subseas of next year
            }
            else
            {
              ALK_idx2=s*N_subseas+1;  //  for the beginning of first subseas of next season
            }
            if(s==nseas) add_age=1; else add_age=0;   //      advance age or not
            VBK_temp2=VBK_temp*VBK_seas(s);
// growth to next season
//  SS_Label_Info_16.2.4.2.1  #standard von Bert growth, loop ages to get size at age at beginning of next season (t+1) which is subseas=1
            for (a=0;a<=nages;a++)
            {
              if(a<nages) {k2=a+add_age;} else {k2=a;}  // where add_age =1 if s=nseas, else 0  (k2 assignment could be in a matrix so not recalculated
// NOTE:  there is no seasonal interpolation, or real age adjustment for age-specific K.  Maybe someday....
              if(lin_grow(g,ALK_idx,a)==-1.0)  // first time point beyond AFIX;  lin_grow will stay at -1 for all remaining subseas of this season
              {
                temp=Cohort_Lmin(gp,y,a) + (Cohort_Lmin(gp,y,a)-LinfR)*(mfexp(VBK_temp2*(real_age(g,ALK_idx2,k2)-AFIX))-1.0)*Cohort_Growth(y,a);
                Ave_Size(t+1,1,g,k2) = pow(temp,inv_Richards);
              }
              else if(lin_grow(g,ALK_idx,a)==-2.0)
              {
                temp=pow(Ave_Size(t,1,g,a),Richards(gp));
                t2=temp-LinfR;  //  remaining growth potential
                if(time_vary_MG(y,2)>0 && t2>-1.)
                {
                  join1=1.0/(1.0+mfexp(-(50.*t2/(1.0+fabs(t2)))));  //  note the logit transform is not perfect, so growth near Linf will not be exactly same as with native growth function
                  t2*=(1.-join1);  // trap to prevent decrease in size-at-age
                }
                if((a<nages || s<nseas)) Ave_Size(t+1,1,g,k2) = 
                  pow((temp+(mfexp(VBK_temp2*seasdur(s))-1.0)*(t2)*Cohort_Growth(y,a)),inv_Richards);
              }
            }  // done ageloop

//  SS_Label_Info_16.2.4.2.1.2  #after age loop, if(s=nseas) get weighted average for size_at_maxage from carryover fish and fish newly moving into this age
            if(s==nseas)
            {
              temp=( (natage(t,1,g,nages-1)+0.01)*Ave_Size(t+1,1,g,nages) + (natage(t,1,g,nages)+0.01)*Ave_Size(t,1,g,nages)) / (natage(t,1,g,nages-1)+natage(t,1,g,nages)+0.02);
              Ave_Size(t+1,1,g,nages)=temp;
            }

            if(docheckup==1) echoinput<<y<<" seas: "<<s<<" sex: "<<sx(g)<<" gp: "<<gp<<" settle: "<<settle_g(g)<<" Lmin: "<<Lmin(gp)<<" Linf: "<<L_inf(gp)<<" VBK: "<<VBK(gp,nages)<<endl
            <<" size@t+1   "<<Ave_Size(t+1,1,g)(0,min(6,nages))<<" "<<Ave_Size(t+1,1,g,nages)<<endl;
          }  // end of season
//  SS_Label_Info_16.2.4.3  #propagate Ave_Size from early years forward until first year that has time-vary growth
          k=y+1;
          j=yz+1;
          while(time_vary_MG(j,2)==0 && k<=YrMax)
          {
            for (s=1;s<=nseas;s++)
            {
              t=styr+(k-styr)*nseas+s-1;
              Ave_Size(t,1,g)=Ave_Size(t-nseas,1,g);
              if(s==1 && k<YrMax)
              {
                Ave_Size(t+nseas,1,g)=Ave_Size(t,1,g);  // prep for time-vary next yr
              }
            }  // end season loop
            k++;
            if(j<endyr+1) j++;
          }
        }  // end need to consider this GP x settlement combo (usemorph>0)
      }  // end loop of settlements
      Ip+=N_M_Grow_parms;
    }    // end loop of growth patterns, gp
  //  SS_Label_Info_16.2.4.4  #end of growth
  } // end do growth2 for Richards

  //  *******************************************************************************************************
  //  SS_Label_Function_16.5  #get_growth3 which calculates mean size-at-age for selected subseason
FUNCTION void get_growth3(const int s, const int subseas)
  {
//  progress mean growth through time series, accounting for seasonality and possible change in parameters
//   get mean size at the beginning and end of the season
    int k2;
    int add_age;
    dvariable LinfR;
    dvariable inv_Richards;

    ALK_idx=(s-1)*N_subseas+subseas;  //  note that this changes a global value
    for (g=g_Start(1)+N_platoon;g<=gmorph;g+=N_platoon)  // looping the middle platoons for each sex*gp
    {
      if(use_morph(g)>0)
      {
        gp=GP(g);
        if(Grow_type==2)
        {
          LinfR=pow(L_inf(gp),Richards(gp));
          inv_Richards=1.0/Richards(gp);
        }
        for (a=0;a<=nages;a++)
        {
//  SS_Label_Info_16.5.1  #calc subseas size-at-age from begin season size-at-age, accounting for transition from linear to von Bert as necessary
          //  subseasdur is cumulative time to start of this subseas
          if(lin_grow(g,ALK_idx,a)>=0.0)  // in linear phase for subseas
          {
            Ave_Size(t,subseas,g,a) = len_bins(1)+lin_grow(g,ALK_idx,a)*(Cohort_Lmin(gp,y,a)-len_bins(1));
          }
// NOTE:  there is no seasonal interpolation, age-specific K uses calendar age, not real age.  Maybe someday....
          else if (Grow_type!=2) // not Richards
          {
            if(lin_grow(g,ALK_idx,a)==-1.0)  // first time point beyond AFIX;  lin_grow will stay at -1 for all remaining subseas of this season
            {
              Ave_Size(t,subseas,g,a) = Cohort_Lmin(gp,y,a) + (Cohort_Lmin(gp,y,a)-L_inf(gp))*
              (mfexp(VBK(gp,a)*(real_age(g,ALK_idx,a)-AFIX)*VBK_seas(s))-1.0)*Cohort_Growth(y,a);
            }
            else if(lin_grow(g,ALK_idx,a)==-2.0)  //  so doing growth curve
            {
              t2=Ave_Size(t,1,g,a)-L_inf(gp);  //  remaining growth potential from first subseas
              if(time_vary_MG(y,2)>0 && t2>-1.)
              {
                join1=1.0/(1.0+mfexp(-(50.*t2/(1.0+fabs(t2)))));  //  note the logit transform is not perfect, so growth near Linf will not be exactly same as with native growth function
                t2*=(1.-join1);  // trap to prevent decrease in size-at-age
              }
              Ave_Size(t,subseas,g,a) = Ave_Size(t,1,g,a) + (mfexp(VBK(gp,a)*subseasdur(s,subseas)*VBK_seas(s))-1.0)*t2*Cohort_Growth(y,a);
            }
          }
          else  //  Richards
          {
            //  uses VBK(nages) because age-specific K not allowed
            //  and Cohort_Lmin has already had the power function applied
            if(lin_grow(g,ALK_idx,a)==-1.0)  // first time point beyond AFIX;  lin_grow will stay at -1 for all remaining subseas of this season
            {
              temp=Cohort_Lmin(gp,y,a) + (Cohort_Lmin(gp,y,a)-LinfR)*
              (mfexp(VBK(gp,nages)*(real_age(g,ALK_idx,a)-AFIX)*VBK_seas(s))-1.0)*Cohort_Growth(y,a);
              Ave_Size(t,subseas,g,a) = pow(temp,inv_Richards);
            }
            else if(lin_grow(g,ALK_idx,a)==-2.0)  //  so doing growth curve
            {
              temp=pow(Ave_Size(t,1,g,a),Richards(gp));
              t2=temp-LinfR;  //  remaining growth potential
              if(time_vary_MG(y,2)>0 && t2>-1.)
              {
                join1=1.0/(1.0+mfexp(-(50.*t2/(1.0+fabs(t2)))));  //  note the logit transform is not perfect, so growth near Linf will not be exactly same as with native growth function
                t2*=(1.-join1);  // trap to prevent decrease in size-at-age
              }
              temp += (mfexp(VBK(gp,nages)*subseasdur(s,subseas)*VBK_seas(s))-1.0)*t2*Cohort_Growth(y,a);
              Ave_Size(t,subseas,g,a) = pow(temp,inv_Richards);
            }
          }
        }  // done ageloop

//  SS_Label_Info_16.5.2  #do calculations related to std.dev. of size-at-age
//  SS_Label_Info_16.5.3 #if (y=styr), calc CV_G(gp,s,a) by interpolation on age or LAA
//  doing this just at y=styr prevents the CV from changing as time-vary growth updates over time
        if(CV_const(gp)>0 && y==styr)
        {
          for (a=0;a<=nages;a++)
          {
            if(real_age(g,ALK_idx,a)<AFIX)
            {CV_G(gp,ALK_idx,a)=CVLmin(gp);}
            else if(real_age(g,ALK_idx,a)>=AFIX2_forCV)
            {CV_G(gp,ALK_idx,a)=CVLmax(gp);}
            else if(CV_depvar_a==0)
            {CV_G(gp,ALK_idx,a)=CVLmin(gp) + (Ave_Size(t,subseas,g,a)-Lmin(gp))*CV_delta(gp);}
            else
            {CV_G(gp,ALK_idx,a)=CVLmin(gp) + (real_age(g,ALK_idx,a)-AFIX)*CV_delta(gp);}
          }   // end age loop
        }
        else
        {
          //  already set constant to CVLmi
        }

//  SS_Label_Info_16.5.4  #calc stddev of size-at-age from CV_G(gp,s,a) and Ave_Size(t,g,a)
        if(CV_depvar_b==0)
        {
          Sd_Size_within(ALK_idx,g)=SD_add_to_LAA+elem_prod(CV_G(gp,ALK_idx),Ave_Size(t,subseas,g));
        }
        else
        {
          Sd_Size_within(ALK_idx,g)=SD_add_to_LAA+CV_G(gp,ALK_idx);
        }

//  SS_Label_Info_16.3.5  #if platoons being used, calc the stddev between platoons
        if(N_platoon>1)
        {
          Sd_Size_between(ALK_idx,g)=Sd_Size_within(ALK_idx,g)*sd_between_platoon;
          Sd_Size_within(ALK_idx,g)*=sd_within_platoon;
        }

        if(docheckup==1)
        {
          echoinput<<"with lingrow; subseas: "<<subseas<<" sex: "<<sx(g)<<" gp: "<<GP4(g)<<" g: "<<g<<endl;
          echoinput<<"size "<<Ave_Size(t,subseas,g)(0,min(6,nages))<<" @nages "<<Ave_Size(t,subseas,g,nages)<<endl;
          echoinput<<"CV   "<<CV_G(gp,ALK_idx)(0,min(6,nages))<<" @nages "<<CV_G(gp,ALK_idx,nages)<<endl;
          echoinput<<"sd   "<<Sd_Size_within(ALK_idx,g)(0,min(6,nages))<<" @nages "<<Sd_Size_within(ALK_idx,g,nages)<<endl;
        }
      }  //  end need this platoon
    }  //  done platoon
  }  //  end  calc size-at-age at a particular subseason


FUNCTION void get_natmort()
  {
  //  SS_Label_Function #17 get_natmort
  dvariable Loren_M1;
  dvariable Loren_temp;
  dvariable Loren_temp2;
  dvariable t_age;
  int gpi;
  int Do_AveAge;
  Do_AveAge=0;
  t_base=styr+(yz-styr)*nseas-1;
  Ip=-N_M_Grow_parms;   // start counter for MGparms
  //  SS_Label_Info_17.1  #loop growth patterns in each gender
  gp=0;
  for (gg=1;gg<=gender;gg++)
  for (GPat=1;GPat<=N_GP;GPat++)
  {
    gp++;
    Ip=MGparm_point(gg,GPat)-1;
  	if(N_natMparms>0)
  	{
  //  SS_Label_Info_17.1.1 #Copy parameter values from mgp_adj to natMparms(gp), doing direct or offset for gp>1
    for (j=1;j<=N_natMparms;j++) {natMparms(j,gp)=mgp_adj(Ip+j);}
    switch(MGparm_def)   //  switch for natmort parms
    {
      case 1:  // direct
      {
      	for (j=1;j<=N_natMparms;j++)
      	{
      		if(natMparms(j,gp)<0) natMparms(j,gp)=natMparms(j,1);
      	}
        break;
      }
      case 2:  // offset
      {
        if(gp>1)
        {
          for (j=1;j<=N_natMparms;j++)
          {
            natMparms(j,gp)=natMparms(j,1)*mfexp(natMparms(j,gp));
          }
        }
        break;
      }
      case 3:  // offset like SS2 V1.23
      {
          if(gp>1) natMparms(1,gp)=natMparms(1,1)*mfexp(natMparms(1,gp));
          if(N_natMparms>1)
          {
          for (j=2;j<=N_natMparms;j++)
          {
            natMparms(j,gp)=natMparms(j-1,gp)*mfexp(natMparms(j,gp));
          }
        }
        break;
      }
    }  // end switch
    }  // end have natmort parms

    g=g_Start(gp);  //  base platoon
    for (settle=1;settle<=N_settle_timings;settle++)
    {
  //  SS_Label_Info_17.1.2  #loop settlements
      g+=N_platoon;
      gpi=GP3(g);   // GP*gender*settlement
      if(use_morph(g)>0)
      {
        switch(natM_type)
        {
  //  SS_Label_Info_17.1.2.0  #case 0:  constant M
          case 0:  // constant M
          {
            for (s=1;s<=nseas;s++)
            {
              if(docheckup==1) echoinput<<"Natmort "<<s<<" "<<gp<<" "<<gpi<<" "<<natMparms(1,gp);
              natM(s,gpi)=natMparms(1,gp);
              surv1(s,gpi)=mfexp(-natMparms(1,gp)*seasdur_half(s));   // refers directly to the constant value
              surv2(s,gpi)=square(surv1(s,gpi));
              if(docheckup==1) echoinput<<" surv "<<surv1(s,gpi)<<endl;
            }
            break;
          }

  //  SS_Label_Info_17.1.2.1  #case 1:  N breakpoints
          case 1:  // breakpoints
          {
            dvariable natM1;
            dvariable natM2;
            for (s=1;s<=nseas;s++)
            {
              if(s>=Bseas(g))
              {a=0; t_age=azero_seas(s)-azero_G(g);}
              else
              {a=1; t_age=1.0+azero_seas(s)-azero_G(g);}
              natM_amax=NatM_break(1);
              natM2=natMparms(1,gp);
              k=a;

              for (loop=1;loop<=N_natMparms+1;loop++)
              {
                natM_amin=natM_amax;
                natM1=natM2;
                if(loop<=N_natMparms)
                {
                  natM_amax=NatM_break(loop);
                  natM2=natMparms(loop,gp);
                }
                else
                {
                  natM_amax=r_ages(nages)+1.;
                }
                if(natM_amax>natM_amin)
                {temp=(natM2-natM1)/(natM_amax-natM_amin);}  //  calc the slope
                else
                {temp=0.0;}
                while(t_age<natM_amax && a<=nages)
                {
                  natM(s,gpi,a)=natM1+(t_age-natM_amin)*temp;
                  t_age+=1.0; a++;
                }
              }
              if(k==1) natM(s,gpi,0)=natM(s,gpi,1);
              surv1(s,gpi)=mfexp(-natM(s,gpi)*seasdur_half(s));
              surv2(s,gpi)=square(surv1(s,gpi));
            } // end season
            break;
          }  // end natM_type==1

  //  SS_Label_Info_17.1.2.2  #case 2:  lorenzen M
          case 2:  //  Lorenzen M
          {
            Loren_temp2=L_inf(gp)*(mfexp(-VBK(gp,nages)*VBK_seas(0))-1.);   // need to verify use of VBK_seas here
            t=styr+(yz-styr)*nseas+Bseas(g)-1;
            Loren_temp=Ave_Size(styr,mid_subseas,g,int(natM_amin));  // uses mean size in middle of season 1 for the reference age
            Loren_M1=natMparms(1,gp)/log(Loren_temp/(Loren_temp+Loren_temp2));
            for (s=nseas;s>=1;s--)
            {
              ALK_idx=(s-1)*N_subseas+mid_subseas;  //  for midseason
              for (a=nages; a>=0;a--)
              {
                if(a==0 && s<Bseas(g))
                {natM(s,gpi,a)=natM(s+1,gpi,a);}
                else
                {natM(s,gpi,a)=log(Ave_Size(t,ALK_idx,g,a)/(Ave_Size(t,ALK_idx,g,a)+Loren_temp2))*Loren_M1;}
                surv1(s,gpi,a)=mfexp(-natM(s,gpi,a)*seasdur_half(s));
                surv2(s,gpi,a)=square(surv1(s,gpi,a));
              }   // end age loop
            }
            break;
          }
  //  SS_Label_Info_17.1.2.3  #case 3:  set to empirical M as read from file, no seasonal interpolation
          case(3):   // read age_natmort as constant
          {
            for (s=1;s<=nseas;s++)
            {
              natM(s,gpi)=Age_NatMort(gp);
              surv1(s,gpi)=value(mfexp(-natM(s,gpi)*seasdur_half(s)));
              surv2(s,gpi)=value(square(surv1(s,gpi)));
            }
            break;
          }

  //  SS_Label_Info_17.1.2.4  #case 4:  read age_natmort as constant and interpolate to seasonal real age
          case(4):
          {
            for (s=1;s<=nseas;s++)
            {
              if(s>=Bseas(g))
              {
                k=0; t_age=azero_seas(s)-azero_G(g);
                for (a=k;a<=nages-1;a++)
                {
                  natM(s,gpi,a) = Age_NatMort(gp,a)+t_age*(Age_NatMort(gp,a+1)-Age_NatMort(gp,a));
                } // end age
              }
              else
              {
                k=1; t_age=azero_seas(s)+(1.-azero_G(g));
                for (a=k;a<=nages-1;a++)
                {
                  natM(s,gpi,a) = Age_NatMort(gp,a)+t_age*(Age_NatMort(gp,a+1)-Age_NatMort(gp,a));
                } // end age
                natM(s,gpi,0)=natM(s,gpi,1);
              }
              natM(s,gpi,nages)=Age_NatMort(gp,nages);
              surv1(s,gpi)=mfexp(-natM(s,gpi)*seasdur_half(s));
              surv2(s,gpi)=square(surv1(s,gpi));
            } // end season
            break;
          }
        }  // end natM_type switch

  //  SS_Label_Info_17.2  #calc an ave_age for the first gp as a scaling factor in logL for initial recruitment (R1) deviation
        if(Do_AveAge==0)
        {
          Do_AveAge=1;
          ave_age = 1.0/natM(1,gpi,nages/2)-0.5;
        }
          if(do_once==1)
             {
         for(s=1;s<=nseas;s++) echoinput<<"Natmort seas:"<<s<<" sex:"<<gg<<" Gpat:"<<GPat<<" sex*Gpat:"<<gp<<" settlement:"<<settle<<" gpi:"<<gpi<<" M: "<<natM(s,gpi)<<endl;
        }
      } //  end use of this morph
    } // end settlement
  }   // end growth pattern x gender loop
  } // end nat mort

FUNCTION void get_recr_distribution()
  {
 /*  SS_Label_Function_18 #get_recr_distribution among areas and morphs */

  if(finish_starter==999)
  {k=MGP_CGD-recr_dist_parms+nseas;}
  else
  {k=MGP_CGD-recr_dist_parms;}
  dvar_vector recr_dist_parm(1,k);

  recr_dist.initialize();
//  SS_Label_Info_18.1  #set rec_dist_parms = exp(mgp_adj) for this year
  Ip=recr_dist_parms-1;
  for (f=1;f<=MGP_CGD-recr_dist_parms;f++)
  {
    recr_dist_parm(f)=mfexp(mgp_adj(Ip+f));
  }
//  SS_Label_Info_18.2  #loop gp * settlements * area and multiply together the recr_dist_parm values
  for (gp=1;gp<=N_GP;gp++)
  for (p=1;p<=pop;p++)
  for (settle=1;settle<=N_settle_timings;settle++)
  if(recr_dist_pattern(gp,settle,p)>0)
  {
    recr_dist(gp,settle,p)=femfrac(gp)*recr_dist_parm(gp)*recr_dist_parm(N_GP+p)*recr_dist_parm(N_GP+pop+settle);
    if(gender==2) recr_dist(gp+N_GP,settle,p)=femfrac(gp+N_GP)*recr_dist_parm(gp)*recr_dist_parm(N_GP+p)*recr_dist_parm(N_GP+pop+settle);  //males
  }
//  SS_Label_Info_18.3  #if recr_dist_interaction is chosen, then multiply these in also
  if(recr_dist_inx==1)
  {
    f=N_GP+nseas+pop;
    for (gp=1;gp<=N_GP;gp++)
    for (p=1;p<=pop;p++)
    for (settle=1;settle<=N_settle_timings;settle++)
    {
      f++;
      if(recr_dist_pattern(gp,settle,p)>0)
      {
        recr_dist(gp,settle,p)*=recr_dist_parm(f);
        if(gender==2) recr_dist(gp+N_GP,settle,p)*=recr_dist_parm(f);
      }
    }
  }
//  SS_Label_Info_18.4  #scale the recr_dist matrix to sum to 1.0
  recr_dist/=sum(recr_dist);
    if(do_once==1) echoinput<<"recruitment distribution in year: "<<y<<"  DIST: "<<recr_dist<<endl;
  }
  
//*******************************************************************
 /*  SS_Label_Function 19 get_wtlen, maturity, fecundity, hermaphroditism */
FUNCTION void get_wtlen()
  {
//  SS_Label_Info_19.1  #set wtlen and maturity/fecundity factors equal to annual values from mgp_adj
  gp=0;
  for (gg=1;gg<=gender;gg++)
  for (GPat=1;GPat<=N_GP;GPat++)
  {
    gp++;
    if(gg==1)
    {
      for(f=1;f<=6;f++) {wtlen_p(GPat,f)=mgp_adj(MGparm_point(gg,GPat)+N_M_Grow_parms+f-1);}
    }
    else
    {
      for(f=7;f<=8;f++) {wtlen_p(GPat,f)=mgp_adj(MGparm_point(gg,GPat)+N_M_Grow_parms+(f-6)-1);}
    }
    echoinput<<"get wtlen parms sex: "<<gg<<" Gpat: "<<GPat<<" sex*Gpat: "<<gp<<" "<<wtlen_p(GPat)<<endl;
  
    for (s=1;s<=nseas;s++)
    {
//  SS_Label_Info_19.2  #loop seasons for wt-len calc
      t=styr+(y-styr)*nseas+s-1;
//  SS_Label_Info_19.2.1  #calc wt_at_length for each season to include seasonal effects on wtlen

//  NOTES  wt_len is by gp, but wt_len2 and wt_len_low have males stacked after females
//  so referenced by GPat

      if(gg==1)
      {
      if(MGparm_seas_effects(1)>0 || MGparm_seas_effects(2)>0 )        //  get seasonal effect on FEMALE wtlen parameters
      {
        wt_len(s,gp)=(wtlen_p(GPat,1)*wtlen_seas(s,GPat,1))*pow(len_bins_m(1,nlength),(wtlen_p(GPat,2)*wtlen_seas(s,GPat,2)));
        wt_len_low(s,GPat)(1,nlength)=(wtlen_p(GPat,1)*wtlen_seas(s,GPat,1))*pow(len_bins2(1,nlength),(wtlen_p(GPat,2)*wtlen_seas(s,GPat,2)));
      }
      else
      {
        wt_len(s,gp) = wtlen_p(GPat,1)*pow(len_bins_m(1,nlength),wtlen_p(GPat,2));
        wt_len_low(s,GPat)(1,nlength) = wtlen_p(GPat,1)*pow(len_bins2(1,nlength),wtlen_p(GPat,2));
      }
      wt_len2(s,GPat)(1,nlength)=wt_len(s,gp)(1,nlength);
      }
//  SS_Label_Info_19.2.2  #calculate male weight_at_length
      else
      {
        if(MGparm_seas_effects(7)>0 || MGparm_seas_effects(8)>0 )        //  get seasonal effect on male wt-len parameters
        {
          wt_len(s,gp) = (wtlen_p(GPat,7)*wtlen_seas(s,GPat,7))*pow(len_bins_m(1,nlength),(wtlen_p(GPat,8)*wtlen_seas(s,GPat,8)));
          wt_len_low(s,GPat)(nlength1,nlength) = (wtlen_p(GPat,7)*wtlen_seas(s,GPat,7))*pow(len_bins2(nlength1,nlength2),(wtlen_p(GPat,8)*wtlen_seas(s,GPat,8)));
        }
        else
        {
          wt_len(s,gp) = wtlen_p(GPat,7)*pow(len_bins_m(1,nlength),wtlen_p(GPat,8));
          wt_len_low(s,GPat)(nlength1,nlength2) = wtlen_p(GPat,7)*pow(len_bins2(nlength1,nlength2),wtlen_p(GPat,8));
        }
        wt_len2(s,GPat)(nlength1,nlength2)=wt_len(s,gp).shift(nlength1);
        wt_len(s,gp).shift(1);
      }
      
//  SS_Label_Info_19.2.3  #calculate first diff of wt_len for use in generalized sizp comp bin calculations
      if(gg==gender)
      {
        wt_len2_sq(s,GPat)=elem_prod(wt_len2(s,GPat),wt_len2(s,GPat));
        wt_len_fd(s,GPat)=first_difference(wt_len_low(s,GPat));
        if(gender==2) wt_len_fd(s,GPat,nlength)=wt_len_fd(s,GPat,nlength-1);
          echoinput<<"wtlen2 "<<endl<<wt_len2<<endl<<"wtlen2^2 "<<wt_len2_sq<<endl<<"wtlen2:firstdiff "<<wt_len_fd<<endl;
      }
  //  SS_Label_Info_19.2.4  #calculate maturity and fecundity if seas = spawn_seas
  //  these calculations are done in spawn_seas, but are not affected by spawn_time within that season
  //  so age-specific inputs will assume to be at correct timing already; size-specific will later be adjusted to use size-at-age at the exact correct spawn_time_seas
//  SPAWN-RECR:   calculate maturity and fecundity vectors
  
      if(s==spawn_seas && gg==1)  // get biology of maturity and fecundity
      {
         echoinput<<"process maturity fecundity using option: "<<Maturity_Option<<endl;
          switch(Maturity_Option)
          {
            case 1:  //  Maturity_Option=1  length logistic
            {
              mat_len(gp) = 1./(1. + mfexp(wtlen_p(GPat,4)*(len_bins_m(1,nlength)-wtlen_p(GPat,3))));
              break;
            }
            case 2:  //  Maturity_Option=2  age logistic
            {
              mat_age(gp) = 1./(1. + mfexp(wtlen_p(GPat,4)*(r_ages-wtlen_p(GPat,3))));
              break;
            }
            case 3:  //  Maturity_Option=3  read age-maturity
            {
              mat_age(gp)=Age_Maturity(gp);
              break;
            }
            case 4:  //  Maturity_Option=4   read age-fecundity, so no age-maturity
            {
              break;
            }
            case 5:  //  Maturity_Option=5   read age-fecundity from wtatage.ss
            {
              break;
            }
            case 6:  //  Maturity_Option=6   read length-maturity
            {
              mat_len(gp)=Length_Maturity(gp);
              break;
            }
          }
           echoinput<<"gp: "<<GPat<<" matlen: "<<mat_len(gp)<<endl;
           echoinput<<"gp: "<<GPat<<" matage: "<<mat_age(gp)<<endl;
          if(First_Mature_Age>0)
          {mat_age(gp)(0,First_Mature_Age-1)=0.;}
            
          switch (Fecund_Option)
          {
            case 1:    // as eggs/kg (SS original configuration)
            {
              fec_len(gp) = wtlen_p(GPat,5)+wtlen_p(GPat,6)*wt_len(s,gp);
              fec_len(gp) = elem_prod(wt_len(s,gp),fec_len(gp));
              break;
            }
            case 2:
            {       // as eggs = f(length)
              fec_len(gp) = wtlen_p(GPat,5)*pow(len_bins_m,wtlen_p(GPat,6));
              break;
            }
            case 3:
            {       // as eggs = f(body weight)
              fec_len(gp) = wtlen_p(GPat,5)*pow(wt_len(s,gp),wtlen_p(GPat,6));
              break;
            }
            case 4:
            {       // as eggs = a + b*Len
              fec_len(gp) = wtlen_p(GPat,5) + wtlen_p(GPat,6)*len_bins_m;
              if(wtlen_p(GPat,5)<0.0)
              {
                z=1;
                while(fec_len(gp,z)<0.0)
                {
                  fec_len(gp,z)=0.0;
                  z++;
                }
              }
              break;
            }
            case 5:
            {       // as eggs = a + b*Wt
              fec_len(gp) = wtlen_p(GPat,5) + wtlen_p(GPat,6)*wt_len(s,gp);
              if(wtlen_p(GPat,5)<0.0)
              {
                z=1;
                while(fec_len(gp,z)<0.0)
                {
                  fec_len(gp,z)=0.0;
                  z++;
                }
              }
              break;
            }
          }
// 1=length logistic; 2=age logistic; 3=read age-maturity
// 4= read age-fecundity by growth_pattern 5=read all from separate wtatage.ss file
//  6=read length-maturity  
     if(Maturity_Option!=4 && Maturity_Option!=5)
     {
       echoinput<<"fec_len "<<endl<<fec_len(gp)<<endl;
  //  combine length maturity and fecundity; but will be ignored if reading empirical age-fecundity
       mat_fec_len(gp) = elem_prod(mat_len(gp),fec_len(gp));
       if(do_once==1) echoinput<<"mat_fec_len "<<endl<<mat_fec_len(gp)<<endl;
     }
     else if(Maturity_Option==4)
      {
        if(do_once==1) echoinput<<"age-fecundity as read from control file"<<endl<<Age_Maturity(gp)<<endl;
      }
      else
     {
        if(do_once==1) echoinput<<"age-fecundity read from wtatage.ss"<<endl;
     }
    }
    }  // end season loop
  }  // end GP loop
//  end wt-len and fecundity

//  SS_Label_Info_19.2.5  #Do Hermaphroditism (no seasonality and no gp differences)
//  should build seasonally component here
//  only one hermaphroditism definition is allowed (3 parameters), but it is stored by Gpat, so referenced by GP4(g)
    if(Hermaphro_Option>0)
    {
      dvariable infl;  // inflection
      dvariable stdev;  // standard deviation
      dvariable maxval;  // max value

      infl=mgp_adj(MGparm_Hermaphro);  // inflection
      stdev=mgp_adj(MGparm_Hermaphro+1);  // standard deviation
      maxval=mgp_adj(MGparm_Hermaphro+2);  // max value
//      minval is 0.0;
      temp2=cumd_norm((0.0-infl)/stdev);     //  cum_norm at age 0
      temp=maxval / (cumd_norm((r_ages(nages)-infl)/stdev)-temp2);   //  delta in cum_norm between styr and endyr
      for (a=0; a<=nages; a++)
      {
        Hermaphro_val(1,a)=0.0 + temp * (cumd_norm((r_ages(a)-infl)/stdev)-temp2);
      }
      if(N_GP>1)
        for(gp=2;gp<=N_GP;gp++)
        {
          Hermaphro_val(gp)=Hermaphro_val(1);
        }
    }

  }

FUNCTION void get_migration()
  {
//*******************************************************************
//  SS_Label_FUNCTION 20 #get_migration
  Ip=MGP_CGD;   // base counter for  movement parms
//  SS_Label_20.1  loop the needed movement rates
  for (k=1;k<=do_migr2;k++)   //  loop all movement rates for this year (includes seas, morphs)
  {
    t=styr+(yz-styr)*nseas+move_def2(k,1)-1;
    if(k<=do_migration) //  so an explicit movement rate
    {
//  set some movement rates same as the first movement rate
      if(mgp_adj(Ip+1)==-9999.) mgp_adj(Ip+1)=mgp_adj(MGP_CGD+1);
      if(mgp_adj(Ip+2)==-9999.) mgp_adj(Ip+2)=mgp_adj(MGP_CGD+2);

//  SS_Label_Info_20.1.1  #age-specific movement strength based on parameters for selected area pairs
      temp=1./(move_def2(k,6)-move_def2(k,5));
      temp1=temp*(mgp_adj(Ip+2)-mgp_adj(Ip+1));
      for (a=0;a<=nages;a++)
      {
        if(a<=move_def2(k,5)) {migrrate(yz,k,a) = mgp_adj(Ip+1);}
        else if(a>=move_def2(k,6)) {migrrate(yz,k,a) = mgp_adj(Ip+2);}
        else {migrrate(yz,k,a) = mgp_adj(Ip+1) + (r_ages(a)-move_def2(k,5))*temp1;}
      }   // end age loop
      migrrate(yz,k)=mfexp(migrrate(yz,k));
      Ip+=2;
    }
    else
//  SS_Label_Info_20.1.2  #default movement strength =1.0 for other area pairs
    {
      migrrate(yz,k)=1.;
    }
  }

//  SS_Label_Info_20.2  #loop seasons, GP, source areas
  for (s=1;s<=nseas;s++)
  {
    t=styr+(yz-styr)*nseas+s-1;
    for (gp=1;gp<=N_GP;gp++)
    {
      for (p=1;p<=pop;p++)
      {
        tempvec_a.initialize();   // zero out the summation vector
        for (p2=1;p2<=pop;p2++)
        {
//  SS_Label_Info_20.2.1  #for each destination area, adjust movement rate by season duration and sum across all destination areas
          k=move_pattern(s,gp,p,p2);
          if(k>0)
          {
            if(p2!=p && nseas>1) migrrate(yz,k)*=seasdur(move_def2(k,1));  // fraction leaving an area is reduced if the season is short
            tempvec_a+=migrrate(yz,k);          //  sum of all movement weights for the p2 fish
          }
        }   //end destination area
//  SS_Label_Info_20.2.2 #now normalize for all movement from source area p
        for (p2=1;p2<=pop;p2++)
        {
          k=move_pattern(s,gp,p,p2);
          if(k>0)
          {
            migrrate(yz,k)=elem_div(migrrate(yz,k),tempvec_a);
  //  SS_Label_Info_20.2.3 #Set rate to 0.0 (or 1.0 for stay rates) below the start age for migration
            if(migr_start(s,gp)>0)
            {
              if(p!=p2)
              {
                migrrate(yz,k)(0,migr_start(s,gp)-1)=0.0;
              }
              else
              {
                migrrate(yz,k)(0,migr_start(s,gp)-1)=1.0;
              }
            }
          }
        }
      }    //  end source areas loop
    }  // end growth pattern
  }  // end season

  //  SS_Label_Info_20.2.4 #Copy annual migration rates forward until first year with time-varying migration rates
  if(yz<endyr)
  {
    k=yz+1;
    while(time_vary_MG(k,5)==0 && k<=endyr)
    {
      migrrate(k)=migrrate(k-1);  k++;
    }
  }
//  end migration
  }

FUNCTION void get_saveGparm()
  {
  //*********************************************************************
  /*  SS_Label_Function_21 #get_saveGparm */
    gp=0;
    for (gg=1;gg<=gender;gg++)
    for (GPat=1;GPat<=N_GP;GPat++)
    {
      gp++;
      g=g_Start(gp);  //  base platoon
      for (settle=1;settle<=N_settle_timings;settle++)
      {
        g+=N_platoon;
        save_gparm++;
        save_G_parm(save_gparm,1)=save_gparm;
        save_G_parm(save_gparm,2)=y;
        save_G_parm(save_gparm,3)=g;
        save_G_parm(save_gparm,4)=AFIX;
        save_G_parm(save_gparm,5)=AFIX2;
        save_G_parm(save_gparm,6)=value(Lmin(gp));
        save_G_parm(save_gparm,7)=value(Lmax_temp(gp));
        save_G_parm(save_gparm,8)=value(-VBK(gp,nages)*VBK_seas(0));
        save_G_parm(save_gparm,9)=value( -log(L_inf(gp)/(L_inf(gp)-Lmin(gp))) / (-VBK(gp,nages)*VBK_seas(0)) +AFIX+azero_G(g) );
        save_G_parm(save_gparm,10)=value(L_inf(gp));
        save_G_parm(save_gparm,11)=value(CVLmin(gp));
        save_G_parm(save_gparm,12)=value(CVLmax(gp));
        save_G_parm(save_gparm,13)=natM_amin;
        save_G_parm(save_gparm,14)=natM_amax;
        save_G_parm(save_gparm,15)=value(natM(1,GP3(g),0));
        save_G_parm(save_gparm,16)=value(natM(1,GP3(g),nages));
        if(gg==1)
        {
        for (k=1;k<=6;k++) save_G_parm(save_gparm,16+k)=value(wtlen_p(GPat,k));
        }
        else
        {
        for (k=1;k<=2;k++) save_G_parm(save_gparm,16+k)=value(wtlen_p(GPat,k+6));
        }
        save_gparm_print=save_gparm;
      }
      if(MGparm_doseas>0)
        {
          for (s=1;s<=nseas;s++)
          {
            for (k=1;k<=8;k++)
            {
            save_seas_parm(s,k)=value(wtlen_p(GPat,k)*wtlen_seas(s,GPat,k));
            }
            save_seas_parm(s,9)=value(Lmin(1));
            save_seas_parm(s,10)=value(VBK(1,nages)*VBK_seas(s));
          }
        }
    }
  }  //  end save_gparm

FUNCTION void Make_Fecundity()
  {
//********************************************************************
//  this Make_Fecundity function does the dot product of the distribution of length-at-age (ALK) with maturity and fecundity vectors
//  to calculate the mean fecundity at each age
 /* SS_Label_31.1 FUNCTION Make_Fecundity */
//  SPAWN-RECR:   here is the make_Fecundity function
    ALK_idx=(spawn_seas-1)*N_subseas+spawn_subseas;
    for (g=1;g<=gmorph;g++)
    if(sx(g)==1)
    {
      GPat=GP4(g);
      gg=sx(g);
      
      switch(Maturity_Option)
      {
        case 4:  //  Maturity_Option=4   read age-fecundity into age-maturity
        {
          fec(g)=Age_Maturity(GPat);
          break;
        }
        case 5:  //  Maturity_Option=5   read age-fecundity from wtatage.ss
        {
          fec(g)=WTage_emp(t,GP3(g),-2);
           break;
        }
        default:
        {
              int ALK_finder=(ALK_idx-1)*gmorph+g;
          for(a=0;a<=nages;a++)
          {
            tempvec_a(a) = ALK(ALK_idx,g,a)(ALK_range_g_lo(ALK_finder,a),ALK_range_g_hi(ALK_finder,a)) *mat_fec_len(GPat)(ALK_range_g_lo(g,a),ALK_range_g_hi(g,a));
          }
          fec(g) = elem_prod(tempvec_a,mat_age(GPat));  //  reproductive output at age
        }
      }

 /*
      switch(Maturity_Option)
      {
        case 1:  //  Maturity_Option=1  length logistic
        {
//          for(a=0;a<=nages;a++)
//          {
//            fec(g,a) = ALK(ALK_idx,g,a)(ALK_range_g_lo(g,a),ALK_range_g_hi(g,a)) *mat_fec_len(GPat)(ALK_range_g_lo(g,a),ALK_range_g_hi(g,a))*mat_age(GPat,a);  //  reproductive output at age
//          }
//          fec(g) = elem_prod(ALK(ALK_idx,g)*mat_fec_len(GPat),mat_age(GPat));  //  reproductive output at age
          break;
        }
        case 2:  //  Maturity_Option=2  age logistic
        {
          fec(g) = elem_prod(ALK(ALK_idx,g)*mat_fec_len(GPat),mat_age(GPat));  //  reproductive output at age
          break;
        }
        case 3:  //  Maturity_Option=3  read age-maturity
        {
          fec(g) = elem_prod(ALK(ALK_idx,g)*mat_fec_len(GPat),mat_age(GPat));  //  reproductive output at age
          break;
        }
        case 4:  //  Maturity_Option=4   read age-fecundity into age-maturity
        {
          fec(g)=Age_Maturity(GPat);
          break;
        }
        case 5:  //  Maturity_Option=5   read age-fecundity from wtatage.ss
        {
          fec(g)=WTage_emp(t,GP3(g),-2);
           break;
        }
        case 6:  //  Maturity_Option=6   read length-maturity
        {
          fec(g) = elem_prod(ALK(ALK_idx,g)*mat_fec_len(GPat),mat_age(GPat));  //  reproductive output at age
          break;
        }
      }
 */
      if( (save_for_report>0) || ((sd_phase() || mceval_phase()) && (initial_params::mc_phase==0)) )
      {
      switch(Maturity_Option)
      {
        case 1:  //  Maturity_Option=1  length logistic
        {
          make_mature_numbers(g)=elem_prod(ALK(ALK_idx,g)*mat_len(GPat),mat_age(GPat));  //  mature numbers at age
          make_mature_bio(g)=elem_prod(ALK(ALK_idx,g)*elem_prod(mat_len(GPat),wt_len(s,GP(g))),mat_age(GPat));  //  mature biomass at age
          
          break;
        }
        case 2:  //  Maturity_Option=2  age logistic
        {
          make_mature_numbers(g)=elem_prod(ALK(ALK_idx,g)*mat_len(GPat),mat_age(GPat));  //  mature numbers at age
          make_mature_bio(g)=elem_prod(ALK(ALK_idx,g)*elem_prod(mat_len(GPat),wt_len(s,GP(g))),mat_age(GPat));  //  mature biomass at age
          break;
        }
        case 3:  //  Maturity_Option=3  read age-maturity
        {
          make_mature_numbers(g)=elem_prod(ALK(ALK_idx,g)*mat_len(GPat),mat_age(GPat));  //  mature numbers at age (Age_Maturity already copied to mat_age)
          make_mature_bio(g)=elem_prod(ALK(ALK_idx,g)*elem_prod(mat_len(GPat),wt_len(s,GP(g))),mat_age(GPat));  //  mature biomass at age
          break;
        }
        case 4:  //  Maturity_Option=4   read age-fecundity, so no age-maturity
        {
          make_mature_numbers(g)=fec(g);  //  not defined
          make_mature_bio(g)=fec(g);   //  not defined
          break;
        }
        case 5:  //  Maturity_Option=5   read age-fecundity from wtatage.ss
        {
          make_mature_numbers(g)=fec(g);  //  not defined
          make_mature_bio(g)=fec(g);   //  not defined
          break;
        }
        case 6:  //  Maturity_Option=6   read length-maturity
        {
          make_mature_numbers(g)=elem_prod(ALK(ALK_idx,g)*mat_len(GPat),mat_age(GPat));  //  mature numbers at age (Length_Maturity already copied to mat_len)
          make_mature_bio(g)=elem_prod(ALK(ALK_idx,g)*elem_prod(mat_len(GPat),wt_len(s,GP(g))),mat_age(GPat));  //  mature biomass at age
          break;
        }
      }
      }
      
 /*
      if(Maturity_Option<=3)
      {
        fec(g) = ALK(ALK_idx,g)*mat_fec_len;
        if(Maturity_Option==3)
        {fec(g) = elem_prod(fec(g),Age_Maturity(GP4(g)));}
        else
        {fec(g) = elem_prod(fec(g),mat_age);}
      }
      else if(Maturity_Option==4)
      {fec(g)=Age_Maturity(GP4(g));}
      else
      {fec(g)=WTage_emp(t,GP3(g),-2);}
 */

        save_sel_fec(t,g,0)= fec(g);   //  save sel_al_3 and save fecundity for output
        if(y==endyr) save_sel_fec(t+nseas,g,0)=fec(g);
        if(save_for_report==2
           && ishadow(GP2(g))==0) bodywtout<<-y<<" "<<s<<" "<<sx(g)<<" "<<GP4(g)<<" "<<Bseas(g)<<" "<<-2<<" "<<fec(g)<<endl;
    }
  }