IMPORT $.^.Types AS Types;
/**
  * Make a sparse NumericField dataset dense by filling
  * in missing values.  All empty cells are set to the designated
  * value.
  *
  *@param d0 They NumericField dataset to be filled.
  *@param v  The value to assign missing records.
  *@return A full NumericField dataset with every field populated.
  */
EXPORT DATASET(Types.NumericField)
       Fat(DATASET(Types.NumericField) d0,
           Types.t_FieldReal v=0) := FUNCTION
  dn := DISTRIBUTE(d0,HASH(wi, id));
  ends := TABLE(dn, {wi, id, m:=MAX(GROUP,number)}, wi, id, LOCAL);
  wi_max := TABLE(ends, {wi, end_fld:=MAX(GROUP, m)}, wi, FEW, UNSORTED);
  Work_Desc := RECORD
    Types.t_Work_Item wi;
    Types.t_RecordID id;
    Types.t_FieldNumber end_fld;
  END;
  Work_Desc get_end(RECORDOF(ends) s, RECORDOF(wi_max) w):=TRANSFORM
    SELF.end_fld := w.end_fld;
    SELF := s;
  END;
  seeds := JOIN(ends, wi_max, LEFT.wi=RIGHT.wi,
                get_end(LEFT,RIGHT), LOOKUP);
  Types.NumericField bv(seeds le,UNSIGNED C) := TRANSFORM
    SELF.wi := le.wi;
    SELF.value := v;
    SELF.id := le.id;
    SELF.number := C;
  END;
  n := NORMALIZE(seeds,LEFT.end_fld, bv(LEFT,COUNTER));
  // subtract from 'n' those values that already exist
  n1 := JOIN(n,dn,
             LEFT.wi=RIGHT.wi AND LEFT.id=RIGHT.id
             AND LEFT.number=RIGHT.number,
             TRANSFORM(LEFT), LEFT ONLY, LOCAL);
  RETURN n1+dn;
END;
