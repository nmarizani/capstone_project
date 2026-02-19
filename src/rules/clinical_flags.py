def clinical_rules(row):
    sbp = row["systolic_bp"]
    dbp = row["diastolic_bp"]
    sugar = row["blood_sugar"]
    preexist = row["preexist_diabetes"]
    gest = row["gest_diabetes"]

    hypertension_flag = int((sbp >= 140) or (dbp >= 90))
    diabetes_any = int((sugar >= 126) or (preexist == 1) or (gest == 1))

    return {
        "hypertension_flag": hypertension_flag,
        "diabetes_any": diabetes_any,
    }

# quick demo on first 5 rows
demo = df.head(5).apply(clinical_rules, axis=1, result_type="expand")
display(pd.concat([df.head(5)[["systolic_bp","diastolic_bp","blood_sugar","preexist_diabetes","gest_diabetes","hypertension_flag","diabetes_any"]], demo.add_prefix("rule_")], axis=1))