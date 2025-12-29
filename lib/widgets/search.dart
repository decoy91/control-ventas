import 'dart:async';
import 'package:flutter/material.dart';

class SearchableBottomSheet<T> extends StatefulWidget {
  final List<T> items;
  final String searchHint;
  final String Function(T item) searchText;
  final Widget Function(T item) itemBuilder;
  final void Function(T item) onSelected;
  final double heightFactor;

  const SearchableBottomSheet({
    super.key,
    required this.items,
    required this.searchHint,
    required this.searchText,
    required this.itemBuilder,
    required this.onSelected,
    this.heightFactor = 0.75,
  });

  @override
  State<SearchableBottomSheet<T>> createState() =>
      _SearchableBottomSheetState<T>();
}

class _SearchableBottomSheetState<T>
    extends State<SearchableBottomSheet<T>> {
  late List<T> filtrados;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    filtrados = List.from(widget.items);
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (debounce?.isActive ?? false) debounce!.cancel();

    debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        filtrados = widget.items
            .where(
              (item) => widget
                  .searchText(item)
                  .toLowerCase()
                  .contains(value.toLowerCase()),
            )
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * widget.heightFactor;

    return SizedBox(
      height: altura,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (_, index) {
                final item = filtrados[index];
                return InkWell(
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                  child: widget.itemBuilder(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
