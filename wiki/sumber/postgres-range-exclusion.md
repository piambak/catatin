---
title: PostgreSQL 17 Documentation — 8.17. Range Types
description: Range types are data types representing a range of values of some element type.
type: source
source_url: https://www.postgresql.org/docs/17/rangetypes.html
media_type: text/html
date_fetched: 2026-09-15
author: The PostgreSQL Global Development Group
preservation: excerpt
tags:
  - source
  - immutable
  - layer-ingest
  - text
---
Kutipan bagian 8.17.3, 8.17.4, 8.17.6, dan 8.17.10 dokumentasi PostgreSQL 17 (versi major proyek Supabase Catatin), diambil dengan `curl` pada 2026-09-15 lalu diekstrak dari HTML. Kata per kata; `[…]` menandai bagian yang dilewati. Dokumentasi PostgreSQL berlisensi PostgreSQL License.

## 8.17.3. Inclusive and Exclusive Bounds

> Every non-empty range has two bounds, the lower bound and the upper bound. All points between these values are included in the range. An inclusive bound means that the boundary point itself is included in the range as well, while an exclusive bound means that the boundary point is not included in the range.
>
> In the text form of a range, an inclusive lower bound is represented by "[" while an exclusive lower bound is represented by "(". Likewise, an inclusive upper bound is represented by "]", while an exclusive upper bound is represented by ")".

## 8.17.4. Infinite (Unbounded) Ranges

> The lower bound of a range can be omitted, meaning that all values less than the upper bound are included in the range, e.g., (,3]. Likewise, if the upper bound of the range is omitted, then all values greater than the lower bound are included in the range.

## 8.17.6. Constructing Ranges and Multiranges

> The two-argument form constructs a range in standard form (lower bound inclusive, upper bound exclusive), while the three-argument form constructs a range with bounds of the form specified by the third argument. The third argument must be one of the strings "()", "(]", "[)", or "[]".
>
> […]
>
> ```sql
> -- Using NULL for either bound causes the range to be unbounded on that side.
> SELECT numrange(NULL, 2.2);
> ```

## 8.17.10. Constraints on Ranges

> While UNIQUE is a natural constraint for scalar values, it is usually unsuitable for range types. Instead, an exclusion constraint is often more appropriate (see CREATE TABLE ... CONSTRAINT ... EXCLUDE). Exclusion constraints allow the specification of constraints such as "non-overlapping" on a range type.
>
> […]
>
> You can use the btree_gist extension to define exclusion constraints on plain scalar data types, which can then be combined with range exclusions for maximum flexibility. For example, after btree_gist is installed, the following constraint will reject overlapping ranges only if the meeting room numbers are equal:
>
> ```sql
> CREATE EXTENSION btree_gist;
> CREATE TABLE room_reservation (
>     room text,
>     during tsrange,
>     EXCLUDE USING GIST (room WITH =, during WITH &&)
> );
> ```
