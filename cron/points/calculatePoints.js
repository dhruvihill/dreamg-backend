const testScore = {
  selectedPoint: 4,
  bat: {
    run: 1,
    boundary: 1,
    six: 2,
    halfCentury: 4,
    century: 8,
    duck: -4,
  },
  bowl: {
    wicket: 16,
    lbwOrBowled: 8,
    fourWicketBouns: 4,
    fiveWicketBouns: 8,
  },
  field: {
    catch: 8,
    stumping: 12,
    runOutDirectHit: 12,
    runOut: 6,
  },
  other: {
    captain: "2x",
    viceCaptain: "1.5x",
    inStarting11: 4,
  },
};

const odiScore = {
  selectedPoint: 4,
  bat: {
    run: 1,
    boundary: 1,
    six: 2,
    halfCentury: 4,
    century: 8,
    duck: -3,
  },
  bowl: {
    wicket: 25,
    lbwOrBowled: 8,
    fourWicketBouns: 4,
    fiveWicketBouns: 8,
    maidenOver: 4,
  },
  field: {
    catch: 8,
    threeCatchBonus: 4,
    stumping: 12,
    runOutDirectHit: 12,
    runOut: 6,
  },
  economy: {
    "below2.5": 6,
    "between2.5-3.49": 4,
    "between3.5-4.5": 2,
    "between7-8": -2,
    "between8.01-9": -4,
    above9: -6,
  },
  strikeRate: {
    // minimum 20 bowl played
    above140: 6,
    "between120.01-140": 4,
    "between100-120": 2,
    "between40-50": -2,
    "between30-39.99": -4,
    below30: -6,
  },
  other: {
    captain: "2x",
    viceCaptain: "1.5x",
    inStarting11: 4,
  },
};

const t20Score = {
  selectedPoint: 4,
  bat: {
    run: 1,
    boundary: 1,
    six: 2,
    thirtyRuns: 4,
    halfCentury: 8,
    century: 16,
    duck: -2,
  },
  bowl: {
    wicket: 25,
    lbwOrBowled: 8,
    threeWicketBouns: 4,
    fourWicketBouns: 8,
    fiveWicketBouns: 16,
    maidenOver: 12,
  },
  field: {
    catch: 8,
    threeCatchBonus: 4,
    stumping: 12,
    runOutDirectHit: 12,
    runOut: 6,
  },
  economy: {
    below5: 6,
    "between5-5.99": 4,
    "between6-7": 2,
    "between10-11": -2,
    "between11.01-12": -4,
    above12: -6,
  },
  strikeRate: {
    // minimum 10 bowl played
    above170: 6,
    "between150.01-170": 4,
    "between130-150": 2,
    "between60-70": -2,
    "between50-59.99": -4,
    below50: -6,
  },
  other: {
    captain: "2x",
    viceCaptain: "1.5x",
    inStarting11: 4,
  },
};

const t10Score = {
  selectedPoint: 4,
  bat: {
    run: 1,
    boundary: 1,
    six: 2,
    halfCentury: 16,
    thirtyRuns: 8,
    duck: -2,
  },
  bowl: {
    wicket: 25,
    lbwOrBowled: 8,
    twoWicketBouns: 8,
    threeWicketBouns: 16,
    maidenOver: 16,
  },
  field: {
    catch: 8,
    threeCatchBonus: 4,
    stumping: 12,
    runOutDirectHit: 12,
    runOut: 6,
  },
  economy: {
    below7: 6,
    "between7-7.99": 4,
    "between8-9": 2,
    "between14-15": -2,
    "between15.01-16": -4,
    above16: -6,
  },
  strikeRate: {
    // minimum 5 bowl played
    above190: 6,
    "between170.01-190": 4,
    "between150-170": 2,
    "between70-80": -2,
    "between60-69.99": -4,
    below60: -6,
  },
  other: {
    captain: "2x",
    viceCaptain: "1.5x",
    inStarting11: 4,
  },
};

module.exports = {
  testScore,
  odiScore,
  t20Score,
  t10Score,
};
